# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via MDSO OCR
    class MdsoOcr < Base
      attr_reader :result

      def self.configured?
        false # TODO: ENV.key?("MDSO_OCR_API_KEY")
      end

      # Using MDSO OCR
      # Documentation: https://docs.mistral.ai/capabilities/document/#ocr-with-image
      def extract_text_from_image
        raise NotImplementedError, "Can not process directly from file, should be in database" unless quote_file

        raise NotImplementedError
      end

      def ocr
        "MdsoOcr"
      end

      private

      def api_key
        ENV.fetch("MDSO_OCR_API_KEY")
      end
    end
  end
end
