# frozen_string_literal: true

require "json"
require "langchain"
require "net/http"
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

      llm = albert_llm
      messages = [
        { role: "system", content: prompt },
        { role: "user", content: text }
      ]

      params = {
        model: @model,
        messages:,
        temperature: 0,
        seed: 42,
        response_format: { type: "json_object", strict: true }
      }

      if json_schema
        params[:response_format] = {
          type: "json_schema",
          json_schema: {
            name: "result",
            strict: true,
            schema: json_schema
          }
        }
      end

      begin
        response = llm.chat(params:)
      rescue Langchain::LLM::ApiError => e
        error_response = e.message

        # Auto switch model if not found (404 error)
        if error_response.include?("404") && model_fallback
          backup_model = (self.class.sort_models(
            models.filter { it.fetch("type") == model_type }
                  .map { it.fetch("id") }
          ) - [model].compact).first
          return chat_completion(text, model: backup_model) if backup_model
        end

        raise ResultError, "Error: #{error_response}"
      end

      @result = response.raw_response
      content = response.chat_completion
      raise ResultError, "Content empty" if content.blank?

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

    def albert_llm
      @albert_llm ||= Langchain::LLM::OpenAI.new(
        api_key: @api_key,
        url: HOST,
        default_options: {
          request: {
            timeout: 300 # seconds
          }
        }
      )
    end

    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }
    end
  end
end
