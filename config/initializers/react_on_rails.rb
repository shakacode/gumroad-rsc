# frozen_string_literal: true

ReactOnRails.configure do |config|
  config.server_bundle_js_file = "server-bundle.js"
  config.enforce_private_server_bundles = true
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"

  # Gumroad wires the demo packs explicitly instead of relying on generated packs.
  config.auto_load_bundle = false
end
