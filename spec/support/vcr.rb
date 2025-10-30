# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes" # Directory where cassettes will be stored
  config.hook_into :webmock # Use WebMock to intercept HTTP requests
  config.configure_rspec_metadata! # Automatically tag RSpec examples with cassette metadata
  config.allow_http_connections_when_no_cassette = true # So we can upsert new cassettes
  config.ignore_localhost = true
  config.debug_logger = File.open("log/vcr_debug.log", "w")

  # Filter sensitive data
  config.filter_sensitive_data("<ALBERT_API_KEY>") { ENV.fetch("ALBERT_API_KEY", "ALBERT_API_KEY") }
  config.filter_sensitive_data("<MDSO_OCR_API_KEY>") { ENV.fetch("MDSO_OCR_API_KEY", "MDSO_OCR_API_KEY") }
  config.filter_sensitive_data("<MDSO_OCR_HOST>") { ENV.fetch("MDSO_OCR_HOST", "http://MDSO_OCR_HOST") }
  config.filter_sensitive_data("<MISTRAL_API_KEY>") { ENV.fetch("MISTRAL_API_KEY", "MISTRAL_API_KEY") }

  # Filter any other potential sensitive key
  ENV.each do |key, value|
    next if config.filtered_values.values.include?(value)

    if key.include?("API_KEY") || key.include?("PASSWORD") || key.include?("SECRET")
      config.filter_sensitive_data("<#{key}>") { value }
    end
  end
end
