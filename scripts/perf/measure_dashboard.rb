# frozen_string_literal: true

require "fileutils"
require "json"
require "cgi"
require "net/http"
require "optparse"
require "openssl"
require "selenium-webdriver"
require "time"
require "uri"

DEFAULTS = {
  base_url: "http://127.0.0.1:3000",
  measure_base_url: nil,
  path: "/dashboard",
  email: "seller@gumroad.com",
  password: "password",
  output_dir: File.expand_path("../../output/playwright/dashboard-perf", __dir__),
  label: "local",
  runs: 3,
  server_warmup_requests: 0,
  timeout: 30,
  headed: false
}.freeze

def parse_options
  options = DEFAULTS.dup

  OptionParser.new do |parser|
    parser.banner = "Usage: ruby scripts/perf/measure_dashboard.rb [options]"

    parser.on("--base-url URL", String) { |value| options[:base_url] = value.sub(%r{/$}, "") }
    parser.on("--measure-base-url URL", String) { |value| options[:measure_base_url] = value.sub(%r{/$}, "") }
    parser.on("--path PATH", String) { |value| options[:path] = value.start_with?("/") ? value : "/#{value}" }
    parser.on("--email EMAIL", String) { |value| options[:email] = value }
    parser.on("--password PASSWORD", String) { |value| options[:password] = value }
    parser.on("--output-dir PATH", String) { |value| options[:output_dir] = File.expand_path(value) }
    parser.on("--label LABEL", String) { |value| options[:label] = value }
    parser.on("--runs N", Integer) { |value| options[:runs] = value }
    parser.on("--server-warmup-requests N", Integer) { |value| options[:server_warmup_requests] = value }
    parser.on("--timeout SECONDS", Integer) { |value| options[:timeout] = value }
    parser.on("--headed") { options[:headed] = true }
  end.parse!

  options
end

def chrome_options(headed:)
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  options.add_argument("--window-size=1440,1100")
  options.add_argument("--disable-popup-blocking")
  options.add_argument("--ignore-certificate-errors")
  options.add_argument("--headless=new") unless headed
  options
end

def build_driver(headed:)
  Selenium::WebDriver.for(:chrome, options: chrome_options(headed:))
end

def build_http_client(base_uri)
  Net::HTTP.new(base_uri.host, base_uri.port).tap do |http|
    if base_uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end
end

def parse_set_cookie(header, request_uri)
  name_value, *attribute_parts = header.split(/;\s*/)
  name, value = name_value.split("=", 2)
  cookie = {
    name:,
    value: value || "",
    domain: request_uri.host,
    path: "/",
    secure: false,
    http_only: false
  }

  attribute_parts.each do |attribute|
    key, raw_value = attribute.split("=", 2)
    normalized_key = key.downcase

    case normalized_key
    when "domain"
      cookie[:domain] = raw_value.to_s.sub(/\A\./, "")
    when "path"
      cookie[:path] = raw_value
    when "secure"
      cookie[:secure] = true
    when "httponly"
      cookie[:http_only] = true
    when "samesite"
      cookie[:same_site] = raw_value&.capitalize
    when "expires"
      cookie[:expiry] = Time.httpdate(raw_value).to_i
    end
  rescue ArgumentError
    nil
  end

  cookie
end

def domain_matches?(host, domain)
  host == domain || host.end_with?(".#{domain}")
end

def cookie_header(cookies, request_uri)
  cookies
    .values
    .select do |cookie|
      domain_matches?(request_uri.host, cookie[:domain]) &&
        request_uri.path.start_with?(cookie[:path]) &&
        (!cookie[:secure] || request_uri.scheme == "https")
    end
    .map { |cookie| "#{cookie[:name]}=#{cookie[:value]}" }
    .join("; ")
end

def perform_request(http, request_uri, request, cookies)
  cookie_value = cookie_header(cookies, request_uri)
  request["Cookie"] = cookie_value unless cookie_value.empty?

  response = http.request(request)
  Array(response.get_fields("Set-Cookie")).each do |header|
    parsed_cookie = parse_set_cookie(header, request_uri)
    cookies["#{parsed_cookie[:domain]}:#{parsed_cookie[:name]}"] = parsed_cookie if parsed_cookie
  end
  response
end

def extract_data_page_props(html)
  data_page = html[/data-page="([^"]+)"/m, 1]
  return nil unless data_page

  parsed = JSON.parse(CGI.unescapeHTML(data_page))
  parsed["props"]
end

def extract_authenticity_token(html)
  props = extract_data_page_props(html)
  props&.fetch("authenticity_token", nil) || html[/name="csrf-token" content="([^"]+)"/, 1]
end

def authenticated_cookies(base_url:, email:, password:)
  base_uri = URI(base_url)
  http = build_http_client(base_uri)
  cookies = {}

  login_uri = URI.join(base_url, "/login")
  login_response = perform_request(http, login_uri, Net::HTTP::Get.new(login_uri), cookies)
  authenticity_token = extract_authenticity_token(login_response.body)
  raise "login authenticity token not found" if authenticity_token.to_s.empty?

  create_login_request = Net::HTTP::Post.new(login_uri)
  create_login_request.set_form_data(
    "user[login_identifier]" => email,
    "user[password]" => password,
    "authenticity_token" => authenticity_token
  )
  create_login_response = perform_request(http, login_uri, create_login_request, cookies)
  redirect_location = create_login_response["location"]
  raise "login redirect location missing" unless redirect_location

  redirect_uri = URI.join(base_url, redirect_location)

  if redirect_uri.path.start_with?("/two-factor")
    two_factor_response = perform_request(http, redirect_uri, Net::HTTP::Get.new(redirect_uri), cookies)
    two_factor_props = extract_data_page_props(two_factor_response.body)
    user_id = two_factor_props&.fetch("user_id", nil)
    raise "two-factor user_id not found" if user_id.to_s.empty?

    token = two_factor_props["token"] || "000000"
    verify_uri = URI.join(base_url, "/two-factor/verify?#{URI.encode_www_form(token:, user_id:)}")
    verify_response = perform_request(http, verify_uri, Net::HTTP::Get.new(verify_uri), cookies)

    if (post_verify_location = verify_response["location"])
      post_verify_uri = URI.join(base_url, post_verify_location)
      perform_request(http, post_verify_uri, Net::HTTP::Get.new(post_verify_uri), cookies)
    end
  else
    perform_request(http, redirect_uri, Net::HTTP::Get.new(redirect_uri), cookies)
  end

  cookies.values
end

def wait_for(driver, timeout:, message: nil, &block)
  Selenium::WebDriver::Wait.new(timeout:, message:).until(&block)
end

def add_lcp_observer(driver)
  driver.execute_cdp(
    "Page.addScriptToEvaluateOnNewDocument",
    source: <<~JS
      (() => {
        window.__codexLcp = null;
        try {
          const observer = new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            const lastEntry = entries[entries.length - 1];
            if (lastEntry) {
              window.__codexLcp = {
                renderTime: lastEntry.renderTime ?? null,
                loadTime: lastEntry.loadTime ?? null,
                startTime: lastEntry.startTime,
                size: lastEntry.size ?? null,
                url: lastEntry.url ?? null
              };
            }
          });

          observer.observe({ type: "largest-contentful-paint", buffered: true });
          window.addEventListener("pagehide", () => observer.disconnect(), { once: true });
        } catch (error) {
          window.__codexLcp = null;
        }
      })();
    JS
  )
rescue StandardError
  nil
end

def wait_for_page_load(driver, timeout:)
  wait_for(driver, timeout:, message: "document never reached readyState=complete") do
    driver.execute_script("return document.readyState") == "complete"
  end
  sleep 2
end

def click_submit(driver, text: nil)
  submit_candidates = driver.find_elements(css: 'button[type="submit"], input[type="submit"]')
  submit = submit_candidates.find do |element|
    next false unless element.displayed?
    next true if text.nil?

    label = element.tag_name == "input" ? element.attribute("value") : element.text
    label&.strip == text
  end
  submit ||= submit_candidates.find(&:displayed?)
  raise "submit button not found" unless submit

  submit.click
end

def find_visible_input(driver, selectors)
  Array(selectors).each do |selector|
    element = driver.find_elements(css: selector).find(&:displayed?)
    return element if element
  end

  nil
end

def maybe_complete_two_factor(driver, timeout:)
  wait_for(driver, timeout:, message: "two-factor page did not load") do
    driver.current_url.include?("/two-factor")
  end
  wait_for_page_load(driver, timeout:)

  page_props = wait_for(driver, timeout:, message: "two-factor props did not load") do
    props = driver.execute_script(<<~JS)
      const pageData = document.querySelector("[data-page]")?.getAttribute("data-page");
      if (!pageData) return null;

      const parsed = JSON.parse(pageData);
      return parsed.props ?? null;
    JS
    props if props.is_a?(Hash) && props["user_id"].to_s != ""
  end

  token = page_props["token"] || "000000"
  user_id = page_props["user_id"]

  verify_query = URI.encode_www_form(token:, user_id:)
  driver.navigate.to("#{driver.current_url.split('/two-factor').first}/two-factor/verify?#{verify_query}")
  wait_for_page_load(driver, timeout:)
rescue Selenium::WebDriver::Error::TimeoutError, Selenium::WebDriver::Error::NoSuchElementError
  nil
end

def log_in(driver, base_url:, email:, password:, timeout:)
  driver.navigate.to("#{base_url}/login")
  wait_for_page_load(driver, timeout:)

  email_input = find_visible_input(driver, ['input[name="user[login]"]', 'input[type="email"]'])
  password_input = find_visible_input(driver, ['input[name="user[password]"]', 'input[type="password"]'])

  raise "login email input not found" unless email_input
  raise "login password input not found" unless password_input

  email_input.send_keys(email)
  password_input.send_keys(password)
  click_submit(driver, text: "Login")
  wait_for_page_load(driver, timeout:)
  maybe_complete_two_factor(driver, timeout:)

  driver.navigate.to("#{base_url}/dashboard")
  wait_for_page_load(driver, timeout:)
  wait_for(driver, timeout:, message: "dashboard did not render an h1") do
    driver.find_elements(css: "h1").any?
  end
end

def page_metrics(driver)
  driver.execute_script(<<~JS)
    const navigation = performance.getEntriesByType("navigation")[0];
    const resources = performance.getEntriesByType("resource");
    const packsResources = resources.filter((entry) => entry.name.includes("/packs/"));
    const jsResources = packsResources.filter((entry) => entry.name.endsWith(".js"));
    const cssResources = packsResources.filter((entry) => entry.name.endsWith(".css"));
    const rscPayloadResources = resources.filter((entry) => entry.name.includes("/rsc_payload/"));
    const dataPage = document.querySelector("[data-page]")?.getAttribute("data-page") ?? null;
    const heading = document.querySelector("h1")?.textContent?.trim() ?? null;
    const pageTitle = document.title ?? null;
    const htmlBytes = document.documentElement?.outerHTML?.length ?? null;
    const bodyTextBytes = document.body?.innerText?.length ?? null;

    const summarizeResources = (entries) => ({
      count: entries.length,
      transferSize: entries.reduce((sum, entry) => sum + (entry.transferSize || 0), 0),
      encodedBodySize: entries.reduce((sum, entry) => sum + (entry.encodedBodySize || 0), 0),
      decodedBodySize: entries.reduce((sum, entry) => sum + (entry.decodedBodySize || 0), 0)
    });

    const largestResources = [...packsResources]
      .sort((left, right) => (right.transferSize || 0) - (left.transferSize || 0))
      .slice(0, 10)
      .map((entry) => ({
        name: entry.name,
        transferSize: entry.transferSize || 0,
        encodedBodySize: entry.encodedBodySize || 0,
        decodedBodySize: entry.decodedBodySize || 0,
        duration: entry.duration
      }));

    return {
      timestamp: new Date().toISOString(),
      url: window.location.href,
      heading,
      pageTitle,
      inertiaDataPageBytes: dataPage?.length ?? null,
      htmlBytes,
      bodyTextBytes,
      navigation: navigation ? {
        domContentLoadedMs: navigation.domContentLoadedEventEnd,
        loadEventMs: navigation.loadEventEnd,
        responseEndMs: navigation.responseEnd,
        durationMs: navigation.duration,
        responseStatus: navigation.responseStatus ?? null,
        transferSize: navigation.transferSize || 0,
        encodedBodySize: navigation.encodedBodySize || 0,
        decodedBodySize: navigation.decodedBodySize || 0
      } : null,
      lcp: window.__codexLcp,
      packs: {
        all: summarizeResources(packsResources),
        js: summarizeResources(jsResources),
        css: summarizeResources(cssResources),
        largest: largestResources
      },
      rscPayload: summarizeResources(rscPayloadResources)
    };
  JS
end

def average(values)
  present = values.compact
  return nil if present.empty?

  (present.sum.to_f / present.length).round(2)
end

def percentile(values, percent)
  present = values.compact.map(&:to_f).sort
  return nil if present.empty?

  index = (percent / 100.0) * (present.length - 1)
  lower_index = index.floor
  upper_index = index.ceil
  lower = present[lower_index]
  upper = present[upper_index]

  (lower + ((upper - lower) * (index - lower_index))).round(2)
end

def standard_deviation(values)
  present = values.compact.map(&:to_f)
  return nil if present.empty?

  mean = present.sum / present.length
  variance = present.sum { |value| (value - mean)**2 } / present.length
  Math.sqrt(variance).round(2)
end

def descriptive_stats(values)
  present = values.compact.map(&:to_f)
  return nil if present.empty?

  {
    count: present.length,
    min: present.min.round(2),
    median: percentile(present, 50),
    p95: percentile(present, 95),
    max: present.max.round(2),
    stddev: standard_deviation(present)
  }
end

def capability_value(capabilities, *keys)
  keys.each do |key|
    return capabilities.public_send(key) if capabilities.respond_to?(key) && !capabilities.public_send(key).nil?
    return capabilities[key] if capabilities.respond_to?(:[]) && !capabilities[key].nil?
    return capabilities[key.to_s] if capabilities.respond_to?(:[]) && !capabilities[key.to_s].nil?
  end

  nil
end

def browser_metadata(driver)
  capabilities = driver.capabilities
  chrome_capabilities = capability_value(capabilities, :chrome)
  chrome_driver_version = if chrome_capabilities.respond_to?(:[])
    chrome_capabilities["chromedriverVersion"]&.split&.first
  end

  {
    browserName: capability_value(capabilities, :browser_name, :browserName),
    browserVersion: capability_value(capabilities, :browser_version, :browserVersion),
    platformName: capability_value(capabilities, :platform_name, :platformName),
    chromeDriverVersion: chrome_driver_version,
    userAgent: driver.execute_script("return navigator.userAgent")
  }.compact
rescue StandardError
  nil
end

def environment_metadata
  {
    measuredAt: Time.now.iso8601,
    rubyVersion: RUBY_VERSION,
    rubyPlatform: RUBY_PLATFORM,
    seleniumVersion: Selenium::WebDriver::VERSION,
    ci: !ENV["CI"].nil?,
    gitSha: ENV["GITHUB_SHA"] || ENV["REVISION"]
  }.compact
end

def page_url(base_url, path)
  URI.join("#{base_url}/", path.delete_prefix("/")).to_s
end

def warm_target_route(target_url:, cookies:, requests:)
  return if requests.to_i <= 0

  target_uri = URI(target_url)
  http = build_http_client(target_uri)

  requests.times do
    response = nil

    5.times do
      response = perform_request(http, target_uri, Net::HTTP::Get.new(target_uri), cookies)
      break if response.is_a?(Net::HTTPSuccess)

      sleep 0.5
    end

    raise "server warmup failed for #{target_url}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  end
end

def validate_metrics!(metrics, target_url:)
  response_status = metrics.dig("navigation", "responseStatus")
  heading = metrics["heading"].to_s
  page_title = metrics["pageTitle"].to_s

  if response_status.to_i >= 400
    raise "page load failed for #{target_url}: HTTP #{response_status} (heading: #{heading.inspect}, title: #{page_title.inspect})"
  end

  return unless [heading, page_title].any? { |value| value.match?(/ReactOnRails::PrerenderError|Internal Server Error|Routing Error|Action Controller: Exception/i) }

  raise "page load rendered an error page for #{target_url} (heading: #{heading.inspect}, title: #{page_title.inspect})"
end

def path_slug(path)
  path
    .delete_prefix("/")
    .gsub(%r{[^a-zA-Z0-9]+}, "-")
    .gsub(/\A-+|-+\z/, "")
    .yield_self { |value| value.empty? ? "root" : value }
end

def summarize_runs(runs)
  {
    navigation: {
      domContentLoadedMs: average(runs.map { |run| run.dig("navigation", "domContentLoadedMs") }),
      loadEventMs: average(runs.map { |run| run.dig("navigation", "loadEventMs") }),
      responseEndMs: average(runs.map { |run| run.dig("navigation", "responseEndMs") }),
      durationMs: average(runs.map { |run| run.dig("navigation", "durationMs") }),
      transferSize: average(runs.map { |run| run.dig("navigation", "transferSize") }),
      encodedBodySize: average(runs.map { |run| run.dig("navigation", "encodedBodySize") }),
      decodedBodySize: average(runs.map { |run| run.dig("navigation", "decodedBodySize") })
    },
    lcp: {
      startTime: average(runs.map { |run| run.dig("lcp", "startTime") }),
      size: average(runs.map { |run| run.dig("lcp", "size") })
    },
    inertiaDataPageBytes: average(runs.map { |run| run["inertiaDataPageBytes"] }),
    htmlBytes: average(runs.map { |run| run["htmlBytes"] }),
    bodyTextBytes: average(runs.map { |run| run["bodyTextBytes"] }),
    packs: {
      transferSize: average(runs.map { |run| run.dig("packs", "all", "transferSize") }),
      encodedBodySize: average(runs.map { |run| run.dig("packs", "all", "encodedBodySize") }),
      decodedBodySize: average(runs.map { |run| run.dig("packs", "all", "decodedBodySize") }),
      jsTransferSize: average(runs.map { |run| run.dig("packs", "js", "transferSize") }),
      cssTransferSize: average(runs.map { |run| run.dig("packs", "css", "transferSize") }),
      jsCount: average(runs.map { |run| run.dig("packs", "js", "count") }),
      cssCount: average(runs.map { |run| run.dig("packs", "css", "count") })
    },
    rscPayload: {
      transferSize: average(runs.map { |run| run.dig("rscPayload", "transferSize") }),
      encodedBodySize: average(runs.map { |run| run.dig("rscPayload", "encodedBodySize") }),
      decodedBodySize: average(runs.map { |run| run.dig("rscPayload", "decodedBodySize") }),
      count: average(runs.map { |run| run.dig("rscPayload", "count") })
    }
  }
end

def summarize_run_distributions(runs)
  {
    navigation: {
      domContentLoadedMs: descriptive_stats(runs.map { |run| run.dig("navigation", "domContentLoadedMs") }),
      loadEventMs: descriptive_stats(runs.map { |run| run.dig("navigation", "loadEventMs") }),
      responseEndMs: descriptive_stats(runs.map { |run| run.dig("navigation", "responseEndMs") }),
      durationMs: descriptive_stats(runs.map { |run| run.dig("navigation", "durationMs") }),
      transferSize: descriptive_stats(runs.map { |run| run.dig("navigation", "transferSize") }),
      encodedBodySize: descriptive_stats(runs.map { |run| run.dig("navigation", "encodedBodySize") }),
      decodedBodySize: descriptive_stats(runs.map { |run| run.dig("navigation", "decodedBodySize") })
    },
    lcp: {
      startTime: descriptive_stats(runs.map { |run| run.dig("lcp", "startTime") }),
      size: descriptive_stats(runs.map { |run| run.dig("lcp", "size") })
    },
    document: {
      inertiaDataPageBytes: descriptive_stats(runs.map { |run| run["inertiaDataPageBytes"] }),
      htmlBytes: descriptive_stats(runs.map { |run| run["htmlBytes"] }),
      bodyTextBytes: descriptive_stats(runs.map { |run| run["bodyTextBytes"] })
    },
    packs: {
      transferSize: descriptive_stats(runs.map { |run| run.dig("packs", "all", "transferSize") }),
      encodedBodySize: descriptive_stats(runs.map { |run| run.dig("packs", "all", "encodedBodySize") }),
      decodedBodySize: descriptive_stats(runs.map { |run| run.dig("packs", "all", "decodedBodySize") }),
      jsTransferSize: descriptive_stats(runs.map { |run| run.dig("packs", "js", "transferSize") }),
      cssTransferSize: descriptive_stats(runs.map { |run| run.dig("packs", "css", "transferSize") }),
      jsCount: descriptive_stats(runs.map { |run| run.dig("packs", "js", "count") }),
      cssCount: descriptive_stats(runs.map { |run| run.dig("packs", "css", "count") })
    },
    rscPayload: {
      transferSize: descriptive_stats(runs.map { |run| run.dig("rscPayload", "transferSize") }),
      encodedBodySize: descriptive_stats(runs.map { |run| run.dig("rscPayload", "encodedBodySize") }),
      decodedBodySize: descriptive_stats(runs.map { |run| run.dig("rscPayload", "decodedBodySize") }),
      count: descriptive_stats(runs.map { |run| run.dig("rscPayload", "count") })
    }
  }
end

def cookie_attributes(cookie)
  allowed = %i[name value path domain secure http_only same_site expiry]
  cookie.select { |key, _value| allowed.include?(key) && !_value.nil? }
end

def main
  options = parse_options
  FileUtils.mkdir_p(options[:output_dir])
  measure_base_url = options[:measure_base_url] || options[:base_url]
  target_url = page_url(measure_base_url, options[:path])
  target_slug = path_slug(options[:path])
  cookies = authenticated_cookies(
    base_url: options[:base_url],
    email: options[:email],
    password: options[:password]
  )
  warm_target_route(
    target_url: target_url,
    cookies: cookies.each_with_object({}) { |cookie, memo| memo["#{cookie[:domain]}:#{cookie[:name]}"] = cookie },
    requests: options[:server_warmup_requests]
  )

  runs = []
  browser = nil

  options[:runs].times do |index|
    driver = build_driver(headed: options[:headed])

    begin
      add_lcp_observer(driver)
      driver.navigate.to(measure_base_url)
      cookies.each { |cookie| driver.manage.add_cookie(cookie_attributes(cookie)) }
      driver.navigate.refresh

      driver.navigate.to(target_url)
      wait_for_page_load(driver, timeout: options[:timeout])
      wait_for(driver, timeout: options[:timeout], message: "#{target_url} did not render an h1") do
        driver.find_elements(css: "h1").any?
      end

      browser ||= browser_metadata(driver)
      metrics = page_metrics(driver)
      validate_metrics!(metrics, target_url:)
      metrics["run"] = index + 1
      runs << metrics

      if index.zero?
        driver.save_screenshot(File.join(options[:output_dir], "#{options[:label]}-#{target_slug}.png"))
      end
    ensure
      driver.quit
    end
  end

  summary = {
    label: options[:label],
    baseUrl: options[:base_url],
    measureBaseUrl: measure_base_url,
    path: options[:path],
    targetUrl: target_url,
    headed: options[:headed],
    runs: options[:runs],
    serverWarmupRequests: options[:server_warmup_requests],
    environment: environment_metadata,
    browser:,
    averages: summarize_runs(runs),
    distributions: summarize_run_distributions(runs),
    samples: runs
  }

  output_path = File.join(options[:output_dir], "#{options[:label]}-#{target_slug}-metrics.json")
  File.write(output_path, JSON.pretty_generate(summary))
  puts JSON.pretty_generate(summary)
end

main
