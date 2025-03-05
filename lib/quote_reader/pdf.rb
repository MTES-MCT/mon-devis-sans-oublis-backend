# frozen_string_literal: true

require "mini_magick"
require "pdf-reader"

module QuoteReader
  # Read Quote from PDF file to extract Quote text
  class Pdf
    class ReadError < QuoteReader::ReadError; end

    attr_reader :content, :text

    def initialize(content)
      @content = content
    end

    def extract_text
      @text = fix_french_characters(extract_text_from_pdf)
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError,
           StandardError => e
      raise parse_error(e)
    end

    # Array of page images (as MiniMagick::Image objects)
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def to_images # rubocop:disable Metrics/MethodLength
      FileUtils.mkdir_p(temp_directory) unless File.directory?(temp_directory)

      random_key = SecureRandom.hex(8)

      # 1. Save PDF to a temporary file
      pdf_file = Tempfile.new(["#{random_key}-", ".pdf"], temp_directory)
      pdf_file.binmode
      pdf_file.write(content)
      pdf_file.close
      pdf_path = pdf_file.path

      # 2. Convert PDF to images
      output_dir = temp_directory.join("#{random_key}/")
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
      output_path = output_dir.join("output_page_") # %02d formats pages as 01, 02, etc.

      # Poppler better than ImageMagick for PDF to PNG conversion
      system("pdftoppm", "-png", "-r", "300", pdf_path, output_path.to_s)

      # MiniMagick::Tool::Convert.new do |convert|
      #   # WARNING: The convert command is deprecated in IMv7, use "magick" instead of "convert" or "magick convert"
      #   convert.density(300)
      #   convert.background("white")
      #   convert.alpha("remove")
      #   convert.quality(100)
      #   convert << pdf_path
      #   convert << "#{output_path}%02d.png"
      # end

      image_paths = Dir.glob(output_dir.join("*")).to_a.sort
      image_paths.map { File.binread(it) }
    ensure
      # 3. Clean up
      image_paths&.each { File.delete(it) }
      FileUtils.rmdir(output_dir) if output_dir
      pdf_file&.unlink
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    private

    def fix_french_characters(text) # rubocop:disable Metrics/MethodLength
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

    def parse_error(error)
      error_message = case error
                      when PDF::Reader::MalformedPDFError
                        "Failed to parse PDF: The file may be corrupted."
                      when PDF::Reader::UnsupportedFeatureError
                        "Failed to parse PDF: An unsupported feature was used in the PDF."
                      when StandardError
                        "An error occurred: #{error.message}"
                      end

      ReadError.new(error_message)
    end

    def extract_text_from_pdf
      io = StringIO.new(content)

      reader = PDF::Reader.new(io)
      raw_text = reader.pages.map(&:text)

      raw_text.join("\n") # Join all pages text into a single string, separated by new lines
    end

    def temp_directory
      Rails.root.join("tmp/quote_reader_pdf/")
    end
  end
end
