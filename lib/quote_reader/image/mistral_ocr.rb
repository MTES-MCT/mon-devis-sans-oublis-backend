# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via Mistral OCR
    class MistralOcr < Base
      attr_reader :result

      def self.configured?
        ENV.key?("MISTRAL_API_KEY")
      end

      # Using Mistral OCR
      # Documentation: https://docs.mistral.ai/capabilities/document/#ocr-with-image
      # rubocop:disable Metrics/AbcSize
      def extract_text_from_image # rubocop:disable Metrics/MethodLength
        raise NotImplementedError, "Can not process directly from file, should be in database" unless quote_file

        uri = URI("https://api.mistral.ai/v1/ocr")
        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{api_key}"
        }

        body = {
          model: "mistral-ocr-latest",
          document: {
            type: "document_url",
            # TODO: sending full file content in Base64 is not working
            # image_url: "data:#{content_type};base64,#{Base64.encode64(content)}"
            image_url: file_image_url, 
            include_image_base64: true
          }
        }

        http = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true)
        http.read_timeout = 120 # seconds
        request = Net::HTTP::Post.new(uri, headers)
        request.body = body.to_json
        response = http.request(request)
        raise TimeoutError if response.code == "504"

        raise ResultError, "Error: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

        @result = JSON.parse(response.body)
        content = result.fetch("pages").map { it.fetch("markdown") }.join("\n").strip
        raise ResultError, "Content empty" unless content

        content
      rescue Net::ReadTimeout => e
        raise TimeoutError, e
      end
      # rubocop:enable Metrics/AbcSize

      private

      def api_key
        ENV.fetch("MISTRAL_API_KEY")
      end

      # Ensure temporary HTTPS secure URL for Mistral to fetch the image
      def file_image_url
        url = Rails.application.routes.url_helpers.rails_blob_url(
          quote_file.file,
          expires_in: 10.minutes,
          host: Rails.application.config.application_host
        )

        uri = URI.parse(url)
        uri.scheme = "https"
        uri.to_s
      end
    end
  end
end
