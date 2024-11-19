# frozen_string_literal: true

require "pdf-reader"

module QuoteReader
  # Read Quote from PDF file to extract Quote text
  class Pdf
    class ReadError < StandardError; end

    attr_reader :filepath, :quote_text

    def initialize(filepath)
      @filepath = filepath
    end

    def extract_text
      fix_french_characters(extract_text_from_pdf(filepath))
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError,
           StandardError
      raise parse_error(error)
    end

    private

    # rubocop:disable Metrics/MethodLength
    def fix_french_characters(text)
      corrections = {
        "ÿ" => " ",
        "oe" => "œ",
        "Ã©" => "é",
        "Ã¨" => "è",
        "Ãª" => "ê",
        "Ã´" => "ô",
        "Ã " => "à",
        "Ã§" => "ç",
        "â" => "'",
        "â" => "-",
        "â¬" => "€"
      }
      corrections.each { |original, replacement| text.gsub!(original, replacement) }

      text
    end
    # rubocop:enable Metrics/MethodLength

    def parse_error(error)
      error_message = case error
                      when PDF::Reader::MalformedPDFError
                        "Failed to parse PDF: The file may be corrupted."
                      when PDF::Reader::UnsupportedFeatureError
                        "Failed to parse PDF: An unsupported feature was used in the PDF."
                      when StandardError
                        "An error occurred: #{e.message}"
                      end

      ReadError.new(error_message)
    end

    def extract_text_from_pdf(pdf_path)
      reader = PDF::Reader.new(pdf_path)
      text = reader.pages.map(&:text)

      text.join("\n") # Join all pages text into a single string, separated by new lines
    end
  end
end
