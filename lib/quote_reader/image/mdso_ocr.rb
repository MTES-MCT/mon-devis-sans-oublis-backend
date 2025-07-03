# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "uri"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via MDSO OCR
    class MdsoOcr < Base
      attr_reader :model, :result

      DEFAULT_MODEL = ENV.fetch("MDSO_OCR_MODEL", "olmocr")
      HOST = ENV.fetch("MDSO_OCR_HOST", "http://localhost:8000")

      def self.configured?
        ENV.key?("MDSO_OCR_API_KEY")
      end

      # Using MDSO OCR
      def extract_text_from_image(model: DEFAULT_MODEL)
        @model = model if model

        content = mdso_ocr(model:)
        raise ResultError, "Content empty" unless content

        @pages_text = @text = content
      rescue Net::ReadTimeout => e
        raise TimeoutError, e
      end

      # rubocop:disable Metrics/AbcSize
      def mdso_ocr(model: nil) # rubocop:disable Metrics/MethodLength
        quote_file.start_processing_log("MdsoOcr", "MdsoOcr/Ocr") do
          io = StringIO.new(quote_file.content)
          file = Faraday::Multipart::FilePart.new(io, content_type, quote_file.filename)
          response = connection.post("ocr/#{model}", { file: file })

          @result = response.body
          case response.status
          when 401, 403
            raise Llms::Albert::UnauthorizedError, result
          end

          raise ResultError, result if !result.is_a?(Hash) || !result.key?("text")

          result.fetch("text")
        end
      end
      # rubocop:enable Metrics/AbcSize

      def models
        connection.get("services").body.fetch("services")
      end

      def ocr
        "MdsoOcr"
      end

      private

      def api_key
        ENV.fetch("MDSO_OCR_API_KEY")
      end

      def connection
        @connection ||= Faraday.new(url: HOST) do |f|
          f.request :multipart
          f.request :url_encoded
          f.request :json
          f.response :json, content_type: /\bjson$/
          f.adapter Faraday.default_adapter
          f.headers["x-api-key"] = api_key
        end
      end
    end
  end
end
