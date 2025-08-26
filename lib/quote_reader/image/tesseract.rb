# frozen_string_literal: true

# skip loading if gem not present
return unless Gem.loaded_specs.key?("rtesseract")

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
      # rubocop:disable Metrics/AbcSize
      def extract_text_from_image # rubocop:disable Metrics/MethodLength
        processing_log = quote_file.start_processing_log("Tesseract") if quote_file

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

          quote_file.end_processing_log(processing_log) if processing_log

          @text
        end
      end
      # rubocop:enable Metrics/AbcSize

      def ocr
        "Tesseract"
      end
    end
  end
end
