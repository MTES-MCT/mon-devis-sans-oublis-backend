# frozen_string_literal: true

require "uri_extended"

require "llms/albert"
require "llms/mistral"
require "llms/ollama"

require "quote_reader/read_error"
require "quote_reader/image/base"
require "quote_reader/image/albert_ocr"
require "quote_reader/image/mdso_ocr"
require "quote_reader/image/mistral_ocr"
require "quote_reader/image/tesseract"

# Custom configuration for Mon Devis Sans Oublis
# added beside common Rails configuration
Rails.application.configure do
  config.app_env = ENV.fetch("APP_ENV", Rails.env)

  config.application_name = "Mon Devis Sans Oublis"
  config.application_host = UriExtended.host_with_port(ENV.fetch("APPLICATION_HOST", "http://localhost:3000"))
  # rubocop:disable Style/RedundantParentheses
  config.application_version = ENV.fetch("CONTAINER_VERSION", (`git rev-parse HEAD`.chomp rescue "unknown")) # rubocop:disable Style/RescueModifier
  # rubocop:enable Style/RedundantParentheses

  config.openapi_file = lambda do |version, section|
    raise ArgumentError, "Invalid section: #{section}" unless %w[internal partner].include?(section)

    "#{config.application_name.parameterize}_api_#{version.downcase}_#{section}_swagger.yaml"
  end

  config.llms_configured = [
    Llms::Mistral,
    Llms::Albert,
    Llms::Ollama
  ].keep_if(&:configured?).map { it.name.split("::").last }

  config.ocrs_configured = [
    QuoteReader::Image::AlbertOcr,
    QuoteReader::Image::MdsoOcr,
    QuoteReader::Image::MistralOcr,
    QuoteReader::Image::Tesseract
  ].keep_if(&:configured?).map { it.name.split("::").last }
end
