# frozen_string_literal: true

require "mini_magick"
require "rtesseract"
require "stringio"
require "tempfile"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via Tesseract OCR
    class Tesseract < Base
      def self.configured?
        true
      end

      # Using Tesseract OCR
      def extract_text_from_image # rubocop:disable Metrics/MethodLength
        extension = determine_extension

        Tempfile.open(["ocr_image", extension]) do |tempfile|
          tempfile.binmode
          tempfile.write(content)
          tempfile.rewind

          # Convert to PNG (if needed) to improve OCR accuracy
          processed_image = MiniMagick::Image.open(tempfile.path)
          processed_image.format("png") unless extension == ".png"

          @pages_text = @text = RTesseract.new(processed_image.path, lang: "fra").to_s # French language
          raise ResultError, "Content empty" unless @text

          @text
        end
      end

      def ocr
        "Tesseract"
      end
    end
  end
end
