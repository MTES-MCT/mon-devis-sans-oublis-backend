# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Llms
  # Mistral API client
  # following OpenAI API structure
  class Mistral < Base
    attr_reader :prompt, :read_attributes, :result

    DEFAULT_MODEL = ENV.fetch("MISTRAL_MODEL", "mistral-large-latest")
    MAX_SCHEMA_SIZE = 15_000 # characters # rails  error "invalid_request_json_schema" with "code" => "3300"

    def initialize(prompt, json_schema: nil, model: DEFAULT_MODEL, result_format: :json)
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
      # TODO: Use ruby_llm
      uri = URI("https://api.mistral.ai/v1/chat/completions")
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }
      body = {
        model:,
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: text }
        ]
      }

      if json_schema
        # See https://docs.mistral.ai/capabilities/structured-output/structured_output_overview/
        body[:response_format] = {
          type: "json_schema",
          json_schema: {
            name: "result",
            strict: true,
            schema: compacted_schema
          }
        }
      end

      http = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true)
      http.read_timeout = 120 # seconds
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body.to_json # doing compact JSON
      response = http.request(request)
      raise TimeoutError if response.code == "504"

      raise ResultError, "Error: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      @result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content")
      raise ResultError, "Content empty" unless content

      extract_result(content)
    rescue Net::ReadTimeout => e
      raise TimeoutError, e
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def model
      result&.fetch("model") || super
    end

    def usage
      result&.fetch("usage")
    end
  end
end
