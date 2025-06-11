# frozen_string_literal: true

module QuoteReader
  class NoFileContentError < StandardError; end
  class UnsupportedFileType < StandardError; end

  # Read Quote from PDF file to extract Quote attributes
  class Global
    attr_reader :content, :content_type,
                :quote_file,
                :ocr,
                :text,
                :shrinked_text,
                :anonymised_text,
                :naive_attributes, :naive_version,
                :private_data_qa_attributes, :private_data_qa_result, :private_data_qa_version,
                :qa_attributes, :qa_result, :qa_version,
                :read_attributes

    DEFAULT_OCR = "AlbertOcr"
    VERSION = "0.0.1"

    def initialize(content, content_type, quote_file: nil)
      @content = content
      @content_type = content_type

      @quote_file = quote_file
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def get_text(force_ocr: false, ocr: nil) # rubocop:disable Metrics/MethodLength
      case content_type
      when "application/pdf"
        return Pdf.new(content).extract_text unless force_ocr
      end

      if force_ocr || QuoteFile.new(content_type:).ocrable?
        begin
          ocr_instance = case ocr || DEFAULT_OCR
                         when "AlbertOcr"
                           Image::AlbertOcr.new(content, content_type, quote_file:)
                         when "MistralOcr"
                           Image::MistralOcr.new(content, content_type, quote_file:)
                         when "Tesseract"
                           Image::Tesseract.new(content, content_type, quote_file:)
                         else
                           raise NotImplementedError, "OCR #{ocr} is not implemented"
                         end

          ocr_instance.extract_text
        ensure
          quote_file&.update!(
            force_ocr:,
            ocr: ocr_instance&.ocr || ocr,
            ocr_result: ocr_instance&.result
          )
        end

        return ocr_instance&.text
      end

      raise QuoteReader::UnsupportedFileType,
            "File type #{content_type} not supported"
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def read(
      force_ocr: false, ocr: nil, qa_llm: nil,
      file_text: nil, file_markdown: nil
    )
      @text = file_markdown || file_text ||
              get_text(force_ocr:, ocr:)

      # TODO: DEPRECATED Remove if not needed anymore
      # naive_reader = NaiveText.new(text)
      @naive_attributes = nil # naive_reader.read
      @naive_version = nil # naive_reader.version

      @shrinked_text = Shrinker.new(text).shrinked_text

      private_data_qa_reader = PrivateDataQa.new(shrinked_text, quote_file:)
      begin
        @private_data_qa_attributes = private_data_qa_reader.read || {}
      ensure
        @private_data_qa_result = private_data_qa_reader.result
        @private_data_qa_version = private_data_qa_reader.version
      end

      private_attributes = deep_merge_if_absent(
        @naive_attributes,
        @private_data_qa_attributes
      )

      private_extended_attributes = deep_merge_if_absent(
        private_attributes,
        ExtendedData.new(private_attributes).extended_attributes
      )
      @anonymised_text = Anonymiser.new(shrinked_text).anonymised_text(private_extended_attributes)

      qa_reader = Qa.new(anonymised_text, quote_file:)
      begin
        @qa_attributes = qa_reader.read(llm: qa_llm) || {}
      ensure
        @qa_result = qa_reader.result
        @qa_version = qa_reader.version
      end

      @read_attributes = TrackingHash.nilify_empty_values(
        deep_merge_if_absent(
          private_extended_attributes,
          qa_attributes
        ),
        compact: true
      )
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def deep_merge_if_absent(hash1, hash2)
      (hash1 || {}).merge(hash2 || {}) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge_if_absent(old_val, new_val)
        elsif old_val.is_a?(Array) && new_val.is_a?(Array)
          (old_val + new_val).presence
        else
          (old_val.nil? ? new_val : old_val).presence
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
