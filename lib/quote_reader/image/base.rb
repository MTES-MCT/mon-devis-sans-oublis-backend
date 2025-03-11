# frozen_string_literal: true

require "stringio"
require "tempfile"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text
    class Base
      class ReadError < QuoteReader::ReadError; end
      class ResultError < QuoteReader::ReadError; end
      class TimeoutError < ResultError; end

      attr_reader :content, :content_type,
                  :quote_file,
                  :text

      def self.configured?
        raise NotImplementedError
      end

      def initialize(content, content_type, quote_file: nil)
        @content = content
        @content_type = content_type
        @quote_file = quote_file
      end

      def extract_text
        # Do not use blank? as it contains non UTF-8 binary data
        raise ReadError, "No content provided" if content.nil? || content.empty? # rubocop:disable Rails/Blank

        @text = extract_text_from_image # TODO: fix_french_characters if needed
      rescue StandardError => e
        raise parse_error(e)
      end

      protected

      def determine_extension
        case content_type
        when "image/jpeg", "image/jpg" then ".jpg"
        when "image/tiff" then ".tiff"
        # when "image/png" # Default fallback
        else ".png"
        end
      end

      private

      def parse_error(error)
        ReadError.new("An error occurred: #{error.message}")
      end

      def extract_text_from_image
        raise NotImplementedError, "Implement in subclass"
      end
    end
  end
end
