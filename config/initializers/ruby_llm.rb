# frozen_string_literal: true

RubyLLM.configure do |config|
  config.mistral_api_key = ENV.fetch("MISTRAL_API_KEY", nil)
  
  # Silence the acts_as deprecation warning
  # We will migrate to the new API when upgrading to RubyLLM 2.0
  config.acts_as_deprecation_silenced = true
end
