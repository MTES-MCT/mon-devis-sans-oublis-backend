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
  config.filter_sensitive_data("<BREVO_API_KEY>") { ENV.fetch("BREVO_API_KEY", "BREVO_API_KEY") }
  config.filter_sensitive_data("<BREVO_SMTP_USER_NAME>") { ENV.fetch("BREVO_SMTP_USER_NAME", "BREVO_SMTP_USER_NAME") }
  config.filter_sensitive_data("<BREVO_SMTP_PASSWORD>") { ENV.fetch("BREVO_SMTP_PASSWORD", "BREVO_SMTP_PASSWORD") }
  config.filter_sensitive_data("<MDSO_OCR_API_KEY>") { ENV.fetch("MDSO_OCR_API_KEY", "MDSO_OCR_API_KEY") }
  config.filter_sensitive_data("<MDSO_OCR_HOST>") { ENV.fetch("MDSO_OCR_HOST", "http://MDSO_OCR_HOST") }
  config.filter_sensitive_data("<MISTRAL_API_KEY>") { ENV.fetch("MISTRAL_API_KEY", "MISTRAL_API_KEY") }
  config.filter_sensitive_data("<RAILS_INBOUND_EMAIL_PASSWORD>") do
    ENV.fetch("RAILS_INBOUND_EMAIL_PASSWORD", "RAILS_INBOUND_EMAIL_PASSWORD")
  end

  # Filter any other potential sensitive key
  sensitive_keys = %w[ALBERT_API_KEY MDSO_OCR_API_KEY MDSO_OCR_HOST MISTRAL_API_KEY]
  ENV.each do |key, value|
    next if sensitive_keys.include?(key)
    next if value.blank?

    if key.include?("API_KEY") || key.include?("PASSWORD") || key.include?("SECRET")
      config.filter_sensitive_data("<#{key}>") { value }
    end
  end
end
