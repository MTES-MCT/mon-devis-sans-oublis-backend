# frozen_string_literal: true

require "json"
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

    DEFAULT_MODEL = ENV.fetch("ALBERT_MODEL", "meta-llama/Meta-Llama-3.1-70B-Instruct")
    HOST = "https://albert.api.etalab.gouv.fr/v1"

    def initialize(prompt, model: DEFAULT_MODEL, result_format: :json)
      super
      @api_key = ENV.fetch("ALBERT_API_KEY")
    end

    def self.configured?
      ENV.key?("ALBERT_API_KEY")
    end

    # API Docs: https://docs.mistral.ai/api/#tag/chat/operation/chat_completion_v1_chat_completions_post
    # TODO: Better client
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # model:
    # - meta-llama/Meta-Llama-3.1-8B-Instruct
    # - meta-llama/Meta-Llama-3.1-70B-Instruct
    # - AgentPublic/llama3-instruct-8b (default)
    # - AgentPublic/Llama-3.1-8B-Instruct
    def chat_completion(text, model: nil, model_fallback: true, model_type: "text-generation")
      @model = model if model

      uri = URI("#{HOST}/chat/completions")
      body = {
        model: @model,
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: text }
        ]
      }

      http = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true)
      http.read_timeout = 120 # seconds
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body.to_json
      response = http.request(request)
      raise TimeoutError if response.code == "504"

      # Auto switch model if not found
      if response.code == "404" && model_fallback
        backup_model = (self.class.sort_models(
          models.filter { it.fetch("type") == model_type }
                .map { it.fetch("id") }
        ) - [model].compact).first
        return chat_completion(text, model: backup_model) if backup_model
      end
      raise ResultError, "Error: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      @result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content")
      raise ResultError, "Content empty" unless content

      extract_result(content)
    rescue Net::ReadTimeout => e
      raise TimeoutError, e
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
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

    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }
    end
  end
end
