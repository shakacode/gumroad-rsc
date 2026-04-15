# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "optparse"
require_relative "measure_dashboard"

COMPARE_DEFAULTS = {
  base_url: DEFAULTS[:base_url],
  measure_base_url: nil,
  paths: [],
  email: DEFAULTS[:email],
  password: DEFAULTS[:password],
  output_dir: DEFAULTS[:output_dir],
  label: "dashboard-comparison",
  cycles: 4,
  server_warmup_requests: 1,
  timeout: DEFAULTS[:timeout],
  headed: false
}.freeze

PRIMARY_COMPARISON_METRICS = {
  navigationDurationMs: %i[navigation durationMs],
  responseEndMs: %i[navigation responseEndMs],
  lcpStartTime: %i[lcp startTime],
  htmlTransferBytes: %i[navigation encodedBodySize],
  jsRequestCount: %i[packs jsCount],
  actionTotalMs: [:serverTiming, "action_total", :durationMs],
  comparePropsMs: [:serverTiming, "compare_props", :durationMs],
  compareCreatorHomeMs: [:serverTiming, "compare_creator_home", :durationMs],
  sqlActiveRecordMs: [:serverTiming, "sql.active_record", :durationMs],
  renderDispatchMs: [:serverTiming, "render_dispatch", :durationMs]
}.freeze

def parse_compare_options
  options = COMPARE_DEFAULTS.dup

  OptionParser.new do |parser|
    parser.banner = "Usage: ruby scripts/perf/compare_dashboard_routes.rb [options]"

    parser.on("--base-url URL", String) { |value| options[:base_url] = value.sub(%r{/$}, "") }
    parser.on("--measure-base-url URL", String) { |value| options[:measure_base_url] = value.sub(%r{/$}, "") }
    parser.on("--path PATH", String) { |value| options[:paths] << (value.start_with?("/") ? value : "/#{value}") }
    parser.on("--email EMAIL", String) { |value| options[:email] = value }
    parser.on("--password PASSWORD", String) { |value| options[:password] = value }
    parser.on("--output-dir PATH", String) { |value| options[:output_dir] = File.expand_path(value) }
    parser.on("--label LABEL", String) { |value| options[:label] = value }
    parser.on("--cycles N", Integer) { |value| options[:cycles] = value }
    parser.on("--server-warmup-requests N", Integer) { |value| options[:server_warmup_requests] = value }
    parser.on("--timeout SECONDS", Integer) { |value| options[:timeout] = value }
    parser.on("--headed") { options[:headed] = true }
  end.parse!

  raise OptionParser::MissingArgument, "at least two --path values are required" if options[:paths].uniq.length < 2

  options[:paths] = options[:paths].uniq
  raise OptionParser::InvalidArgument, "--cycles must be positive" if options[:cycles] <= 0
  raise OptionParser::InvalidArgument, "--server-warmup-requests must be zero or greater" if options[:server_warmup_requests].negative?

  if (options[:cycles] % options[:paths].length).nonzero?
    raise OptionParser::InvalidArgument,
          "--cycles must be a multiple of the compared path count (#{options[:paths].length}) so route order stays balanced"
  end

  options
end

def build_cycle_orders(paths, cycles)
  Array.new(cycles) do |index|
    paths.rotate(index % paths.length)
  end
end

def compare_output_dir(options)
  File.join(options[:output_dir], "#{options[:label]}-runs")
end

def measurement_command(measure_script_path:, options:, path:, run_label:, output_dir:)
  command = [
    Gem.ruby,
    measure_script_path,
    "--base-url", options[:base_url],
    "--path", path,
    "--email", options[:email],
    "--password", options[:password],
    "--output-dir", output_dir,
    "--label", run_label,
    "--runs", "1",
    "--server-warmup-requests", options[:server_warmup_requests].to_s,
    "--timeout", options[:timeout].to_s,
    "--skip-screenshot"
  ]

  command.concat(["--measure-base-url", options[:measure_base_url]]) if options[:measure_base_url]
  command << "--headed" if options[:headed]
  command
end

def execute_measurement!(measure_script_path:, options:, path:, cycle_index:, position_index:)
  output_dir = compare_output_dir(options)
  FileUtils.mkdir_p(output_dir)

  run_label = "#{options[:label]}-cycle#{cycle_index + 1}-position#{position_index + 1}"
  command = measurement_command(
    measure_script_path:,
    options:,
    path:,
    run_label:,
    output_dir:
  )

  stdout, stderr, status = Open3.capture3(*command)
  unless status.success?
    warn stdout unless stdout.empty?
    warn stderr unless stderr.empty?
    raise "measurement failed for #{path} at cycle #{cycle_index + 1}, position #{position_index + 1}"
  end

  summary_path = File.join(output_dir, "#{run_label}-#{path_slug(path)}-metrics.json")
  summary = JSON.parse(File.read(summary_path))
  sample = summary.fetch("samples").fetch(0)
  sample["measurementLabel"] = summary["label"]
  sample["cycle"] = cycle_index + 1
  sample["positionInCycle"] = position_index + 1
  sample["requestedPath"] = path

  { summary:, sample:, summary_path:, stdout:, stderr: }
end

def summarize_position_effects(samples)
  samples
    .group_by { |sample| sample["positionInCycle"] }
    .sort_by(&:first)
    .to_h do |position, positioned_samples|
      [
        position.to_s,
        {
          count: positioned_samples.length,
          averages: summarize_runs(positioned_samples),
          distributions: summarize_run_distributions(positioned_samples)
        }
      ]
    end
end

def summarize_paths(path_samples)
  path_samples.transform_values do |samples|
    {
      count: samples.length,
      averages: summarize_runs(samples),
      distributions: summarize_run_distributions(samples),
      byExecutionPosition: summarize_position_effects(samples)
    }
  end
end

def metric_delta(reference, candidate)
  return nil if reference.nil? || candidate.nil?
  return nil if reference.to_f.zero?

  ((candidate - reference) / reference.to_f * 100).round(1)
end

def summarize_primary_deltas(path_summaries, baseline_path, candidate_path)
  PRIMARY_COMPARISON_METRICS.each_with_object({}) do |(metric_name, key_path), summary|
    baseline_value = path_summaries.dig(baseline_path, :averages, *key_path)
    candidate_value = path_summaries.dig(candidate_path, :averages, *key_path)

    summary[metric_name] = {
      baselinePath: baseline_path,
      candidatePath: candidate_path,
      baselineValue: baseline_value,
      candidateValue: candidate_value,
      deltaPercent: metric_delta(baseline_value, candidate_value)
    }
  end
end

def build_comparison_summary(paths, path_summaries)
  baseline_path = paths.first

  {
    baselinePath: baseline_path,
    candidates: paths.drop(1).map do |candidate_path|
      {
        candidatePath: candidate_path,
        primaryMetricDeltas: summarize_primary_deltas(path_summaries, baseline_path, candidate_path)
      }
    end
  }
end

def main
  options = parse_compare_options
  measure_script_path = File.expand_path("measure_dashboard.rb", __dir__)
  cycle_orders = build_cycle_orders(options[:paths], options[:cycles])

  path_samples = options[:paths].each_with_object({}) { |path, memo| memo[path] = [] }
  ordered_measurements = []
  browser = nil
  environment = nil

  cycle_orders.each_with_index do |paths_for_cycle, cycle_index|
    paths_for_cycle.each_with_index do |path, position_index|
      result = execute_measurement!(
        measure_script_path:,
        options:,
        path:,
        cycle_index:,
        position_index:
      )

      browser ||= result[:summary]["browser"]
      environment ||= result[:summary]["environment"]
      path_samples[path] << result[:sample]
      ordered_measurements << {
        cycle: cycle_index + 1,
        positionInCycle: position_index + 1,
        path:,
        label: result[:summary]["label"],
        summaryPath: result[:summary_path]
      }
    end
  end

  path_summaries = summarize_paths(path_samples)
  comparison = build_comparison_summary(options[:paths], path_summaries)

  output = {
    label: options[:label],
    method: "alternating_cycles",
    cycles: options[:cycles],
    paths: options[:paths],
    baseUrl: options[:base_url],
    measureBaseUrl: options[:measure_base_url] || options[:base_url],
    serverWarmupRequestsPerRun: options[:server_warmup_requests],
    environment:,
    browser:,
    cycleOrders: cycle_orders,
    orderedMeasurements: ordered_measurements,
    pathSummaries: path_summaries.transform_keys(&:to_s),
    comparison:
  }

  output_path = File.join(options[:output_dir], "#{options[:label]}-comparison.json")
  File.write(output_path, JSON.pretty_generate(output))
  puts JSON.pretty_generate(output)
end

main if $PROGRAM_NAME == __FILE__
