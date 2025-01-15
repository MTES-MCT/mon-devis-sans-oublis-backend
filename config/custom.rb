# frozen_string_literal: true

require "llms/albert"
require "llms/mistral"
require "llms/ollama"

# Custom configuration for Mon Devis Sans Oublis
# added beside common Rails configuration
Rails.application.configure do
  config.app_env = ENV.fetch("APP_ENV", Rails.env)

  config.application_name = "Mon Devis Sans Oublis"
  config.application_version = ENV.fetch("CONTAINER_VERSION", (`git rev-parse HEAD`.chomp rescue "unknown")) # rubocop:disable Style/RescueModifier

  config.openapi_file = lambda { |version|
    "#{config.application_name.parameterize}_api_#{version.downcase}_swagger.yaml"
  }

  config.llms_configured = [
    Llms::Mistral,
    Llms::Albert,
    Llms::Ollama
  ].keep_if(&:configured?).map { it.name.split("::").last }
end
