# frozen_string_literal: true

require "json"
require "langchain"
require "net/http"
require "uri"

module Llms
  # Ollama API client
  class Ollama < Base
    attr_reader :ollama_host, :prompt, :read_attributes, :result

    def initialize(prompt)
      super
      @ollama_host = ENV.fetch("OLLAMA_HOST")
    end

    def self.configured?
      ENV.key?("OLLAMA_HOST")
    end

    # API Docs: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion
    # TODO: Better client
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def chat_completion(text, model: "llama3.2")
      # TODO: Use ruby_llm
      messages = [
        { role: "system", content: prompt },
        { role: "user", content: text }
      ]

      uri = URI("#{ollama_host}/api/chat")
      body = {
        model: model,
        messages:,
        stream: false
      }

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: Rails.env.production?) do |http|
        request = Net::HTTP::Post.new(uri)
        request.body = body.to_json
        http.request(request)
      end
      raise TimeoutError if response.code == "504"

      raise ResultError, "Error: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      @result = JSON.parse(response.body.force_encoding("UTF-8"))
      content = result.dig(0, "response")
      raise ResultError, "Content empty" unless content

      extract_result(content)
    rescue Net::ReadTimeout => e
      raise TimeoutError, e
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def model
      result&.fetch("model")
    end

    def usage
      result&.fetch("usage")
    end
  end
end
