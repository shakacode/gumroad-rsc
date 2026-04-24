# frozen_string_literal: true

module DashboardComparisonTiming
  extend ActiveSupport::Concern

  included do
    after_action :write_dashboard_comparison_server_timing
  end

  private
    def with_dashboard_comparison_timing(metric_name)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
    ensure
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(2)
      dashboard_comparison_timing_metrics << { name: metric_name, duration_ms: }
    end

    def dashboard_comparison_timing_metrics
      @dashboard_comparison_timing_metrics ||= []
    end

    def write_dashboard_comparison_server_timing
      return if dashboard_comparison_timing_metrics.blank?

      serialized_metrics = dashboard_comparison_timing_metrics.map do |metric|
        "#{metric[:name]};dur=#{format('%.2f', metric[:duration_ms])}"
      end.join(", ")

      existing_metrics = response.get_header("Server-Timing")
      response.set_header("Server-Timing", [existing_metrics, serialized_metrics].compact_blank.join(", "))
    end
end
