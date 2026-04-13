# frozen_string_literal: true

ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = ENV.fetch("REACT_RENDERER_URL", "http://localhost:3800")
  config.renderer_password = ENV.fetch("RENDERER_PASSWORD", "devPassword")
  config.ssr_timeout = 5
  config.renderer_request_retry_limit = 1
  config.renderer_use_fallback_exec_js = Rails.env.development?
  config.throw_js_errors = false
  config.prerender_caching = true
  config.tracing = Rails.env.development?

  config.enable_rsc_support = true
  config.rsc_bundle_js_file = "rsc-bundle.js"
  config.rsc_payload_generation_url_path = "rsc_payload/"
end
