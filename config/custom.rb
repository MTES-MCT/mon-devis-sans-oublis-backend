# frozen_string_literal: true

require "uri_extended"

require "llms/albert"
require "llms/mistral"
require "llms/ollama"

require "quote_reader/read_error"
require "quote_reader/image/base"
Rails.root.glob("lib/quote_reader/image/*.rb").each do |filepath|
  require_relative(filepath) unless filepath.to_s.end_with?("base.rb")
end

# Custom configuration for Mon Devis Sans Oublis
# added beside common Rails configuration
Rails.application.configure do
  config.app_env = ENV.fetch("APP_ENV", Rails.env)

  config.application_name = "Mon Devis Sans Oublis"
  config.application_host = UriExtended.host_with_port(ENV.fetch("APPLICATION_HOST", "http://localhost:3000"))
  config.application_version = ENV.fetch("CONTAINER_VERSION", (`git rev-parse HEAD`.chomp rescue "unknown")) # rubocop:disable Style/RescueModifier
  config.openapi_file = lambda do |version, section|
    raise ArgumentError, "Invalid section: #{section}" unless %w[internal partner].include?(section)

    "#{config.application_name.parameterize}_api_#{version.downcase}_#{section}_swagger.yaml"
  end

  config.llms_configured = [
    Llms::Mistral,
    Llms::Albert,
    Llms::Ollama
  ].keep_if(&:configured?).map { it.name.split("::").last }

  # OCR will be auto-selected and retrieved via the class name and its class name method.
  config.ocrs_configured = [
    QuoteReader::Image::AlbertOcr,

    # MDSO OCRs
    QuoteReader::Image::MdsoOcrDotsOcr,
    QuoteReader::Image::MdsoOcrMarker,
    QuoteReader::Image::MdsoOcrNanonets,
    QuoteReader::Image::MdsoOcrOlmOcr,

    QuoteReader::Image::MistralOcr,
    QuoteReader::Image::Tesseract
  ].keep_if(&:configured?).map { it.name.split("::").last }
end
