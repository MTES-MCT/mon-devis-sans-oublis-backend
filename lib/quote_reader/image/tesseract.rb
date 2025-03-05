# frozen_string_literal: true

require "mini_magick"
require "rtesseract"
require "stringio"
require "tempfile"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via Tesseract OCR
    class Tesseract < Base
      private

      # Using Tesseract OCR
      def extract_text_from_image
        extension = determine_extension

        Tempfile.open(["ocr_image", extension]) do |tempfile|
          tempfile.binmode
          tempfile.write(content)
          tempfile.rewind

          # Convert to PNG (if needed) to improve OCR accuracy
          processed_image = MiniMagick::Image.open(tempfile.path)
          processed_image.format("png") unless extension == ".png"

          RTesseract.new(processed_image.path, lang: "fra").to_s # French language
        end
      end

      def determine_extension
        case content_type
        when "image/jpeg", "image/jpg" then ".jpg"
        when "image/tiff" then ".tiff"
        # when "image/png" # Default fallback
        else ".png"
        end
      end
    end
  end
end
