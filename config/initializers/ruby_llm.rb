# frozen_string_literal: true

RubyLLM.configure do |config|
  config.mistral_api_key = ENV.fetch("MISTRAL_API_KEY", nil)
end
