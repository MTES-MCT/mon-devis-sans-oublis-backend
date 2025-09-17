# frozen_string_literal: true

require "json"
require "net/http"
require "ruby_llm"
require "uri"

require_relative "base"

module Llms
  # Albert API client : following OpenAI API structure
  # Documentation https://github.com/etalab-ia/albert-api
  class Albert < Base
    class ResponseError < StandardError; end
    class UnauthorizedError < ResponseError; end

    attr_reader :prompt, :read_attributes, :result

    DEFAULT_MODEL = ENV.fetch("ALBERT_MODEL", "albert-large")
    HOST = "https://albert.api.etalab.gouv.fr/v1"

    def initialize(prompt, json_schema: nil, model: DEFAULT_MODEL, result_format: :json)
      super
      @api_key = ENV.fetch("ALBERT_API_KEY")
    end

    def self.configured?
      ENV.key?("ALBERT_API_KEY")
    end

    # TODO: Better client
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # model:
    # - meta-llama/Meta-Llama-3.1-8B-Instruct
    # - AgentPublic/llama3-instruct-8b (default)
    # - AgentPublic/Llama-3.1-8B-Instruct
    def chat_completion(text, model: nil, model_fallback: true, model_type: "text-generation") # rubocop:disable Metrics/MethodLength
      @model = model if model

      chat = albert_context.chat(
        model: @model,
        provider: :openai, # Albert API is compatible with OpenAI API and mandatory for custom host context
        assume_model_exists: true
      )
      chat.with_instructions(prompt)

      ruby_llm_message = nil
      begin
        ruby_llm_message = json_schema ? chat.with_schema(json_schema).ask(text) : chat.ask(text)
      rescue RubyLLM::Error => e
        response = e.response

        # Auto switch model if not found
        if response.status == 404 && model_fallback
          backup_model = (self.class.sort_models(
            models.filter { it.fetch("type") == model_type }
                  .map { it.fetch("id") }
          ) - [model].compact).first
          return chat_completion(text, model: backup_model) if backup_model
        end

        raise ResultError, "Error: #{response.status} - #{response.body}"
      end
      response = ruby_llm_message.raw

      @result = response.body
      # content = result.dig("choices", 0, "message", "content")
      content = ruby_llm_message.content
      raise ResultError, "Content empty" if content.blank?

      return TrackingHash.nilify_empty_values(content.deep_symbolize_keys) if json_schema

      extract_result(content)
    rescue Net::ReadTimeout => e
      raise TimeoutError, e
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def models # rubocop:disable Metrics/MethodLength
      uri = URI("#{HOST}/models")

      http = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https")
      request = Net::HTTP::Get.new(uri, headers)
      response = http.request(request)

      json = JSON.parse(response.body)
      case response.code
      when "401", "403"
        raise UnauthorizedError, json.fetch("detail")
      else
        raise ResponseError, json.fetch("detail") if response.code != "200"
      end

      json.fetch("data")
    end
    # rubocop:enable Metrics/AbcSize

    def model
      result&.fetch("model") || super
    end

    def usage
      result&.fetch("usage")
    end

    private

    def albert_context
      @albert_context ||= RubyLLM.context do |config|
        config.openai_use_system_role = true # Use 'system' role instead of 'developer' for instructions messages
        config.openai_api_key = @api_key
        config.openai_api_base = HOST
        config.request_timeout = 300 # seconds
      end
    end

    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }
    end
  end
end
