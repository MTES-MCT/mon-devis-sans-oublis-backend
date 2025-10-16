# frozen_string_literal: true

require "json"
require "net/http"
require "ruby_llm"
require "uri"

module Llms
  # Mistral API client
  # following OpenAI API structure
  class Mistral < Base
    attr_reader :prompt, :read_attributes, :result

    DEFAULT_MODEL = ENV.fetch("MISTRAL_MODEL", "mistral-large-latest")
    MAX_SCHEMA_SIZE = 15_000 # characters # rails  error "invalid_request_json_schema" with "code" => "3300"

    def initialize(prompt, # rubocop:disable Metrics/ParameterLists
                   json_schema: nil, model: DEFAULT_MODEL, result_format: :json,
                   xml_root_name: nil, xml_root_attrs: nil)
      super
      @api_key = ENV.fetch("MISTRAL_API_KEY")
    end

    # Returns the cost in € with VAT
    PROMPT_TOKEN_COST = 0.0018 / 1000 * 1.2
    COMPLETION_TOKEN_COST = 0.0054 / 1000 * 1.2
    def self.usage_cost_price(prompt_tokens: 0, completion_tokens: 0)
      # Rounded to the last started thousand
      price = ((prompt_tokens.to_f / 1000).ceil * 1000 * PROMPT_TOKEN_COST).ceil(2) +
              ((completion_tokens.to_f / 1000).ceil * 1000 * COMPLETION_TOKEN_COST).ceil(2)
      price.ceil(2)
    end

    def self.configured?
      ENV.key?("MISTRAL_API_KEY")
    end

    # API Docs: https://docs.mistral.ai/api/#tag/chat/operation/chat_completion_v1_chat_completions_post
    # TODO: Better client
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def chat_completion(text, model: @model)
      @model = model if model

      chat = mistral_context
             .chat(
               provider: :mistral,
               model: @model
             )
             .with_temperature(0)
             .with_params(seed: 42)
             .with_params(response_format: { type: "json_object" }) # Mistral API does not support "strict" mode
      chat.with_instructions(prompt)

      ruby_llm_message = nil
      begin
        ruby_llm_message = (json_schema ? chat.with_schema(json_schema) : chat).ask(text)
      rescue RubyLLM::Error => e
        response = e.response

        raise ResultError, "Error: #{response.status} - #{response.body}"
      end
      response = ruby_llm_message.raw

      @result = response.body
      # content = result.dig("choices", 0, "message", "content")
      content = ruby_llm_message.content
      raise ResultError, "Content empty" if content.blank?

      extract_result(content)
    rescue Net::ReadTimeout => e
      raise TimeoutError, e
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def model
      result&.fetch("model") || super
    end

    def models
      RubyLLM.models.by_provider(:mistral).map(&:to_h)
    end

    def usage
      result&.fetch("usage")
    end

    private

    def mistral_context
      @mistral_context ||= RubyLLM.context do |config|
        config.request_timeout = REQUEST_TIMEOUT # seconds
      end
    end
  end
end
