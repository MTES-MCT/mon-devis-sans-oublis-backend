# frozen_string_literal: true

# This class is responsible for checking the quote and returning the result.
class QuoteCheckService # rubocop:disable Metrics/ClassLength
  attr_reader :quote_check, :save

  # rubocop:disable Metrics/ParameterLists
  def initialize( # rubocop:disable Metrics/MethodLength
    tempfile_or_quote_check, filename = nil,
    profile = nil,
    content_type: nil, metadata: nil, case_id: nil, parent_id: nil,
    file_text: nil, file_markdown: nil,
    reference: nil, source_name: nil,
    save: true
  )
    @quote_check = if tempfile_or_quote_check.is_a?(QuoteCheck)
                     tempfile_or_quote_check
                   else
                     QuoteCheckUploadService.new(
                       tempfile_or_quote_check, filename, profile,
                       file_text:, file_markdown:,
                       content_type:, metadata:, case_id:, parent_id:,
                       reference:, source_name:
                     ).upload
                   end
    @save = save
  end
  # rubocop:enable Metrics/ParameterLists

  def self.quote_fields
    quote_validation = QuoteValidator::Global.new({})
    quote_validation.validate!
    quote_validation.fields
  end

  def self.default_quote_attributes(fields = quote_fields)
    fields.to_h do |field|
      if field.is_a?(Hash)
        [field.keys.first, default_quote_attributes(field.values.first)]
      elsif field.is_a?(Array)
        field
      else
        [field, nil]
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def check(force_ocr: false, ocr: nil, qa_llm: nil) # rubocop:disable Metrics/MethodLength
    ErrorNotifier.set_context(:quote_check, { id: quote_check.id })

    begin
      reset_check
      read_quote(force_ocr:, ocr:, qa_llm:)
      validate_quote if quote_check.validation_errors.blank?
      quote_check.finished_at = Time.current
    ensure
      quote_check.application_version = Rails.application.config.application_version
      quote_check.save! if save
    end

    quote_check
  end
  # rubocop:enable Metrics/AbcSize

  private

  # rubocop:disable Metrics/AbcSize
  def add_error(code,
                category: nil, type: nil,
                title: nil)
    quote_check.validation_errors ||= []
    quote_check.validation_errors << code

    quote_check.validation_error_details ||= []
    quote_check.validation_error_details << {
      id: [quote_check.id, quote_check.validation_error_details.count + 1].compact.join("-"),
      code:,
      category:, type:,
      title: title || I18n.t("quote_validator.errors.#{code}")
    }
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def read_quote(force_ocr: false, ocr: nil, qa_llm: nil)
    quote_reader = QuoteReader::Global.new(
      quote_check.file.content,
      quote_check.file.content_type,
      quote_file: quote_check.file
    )
    QuoteFileImagifyPdfJob.perform_later(quote_check.file_id) # TODO: Move it to reader?

    begin
      quote_reader.read(
        force_ocr:, ocr:, qa_llm:,
        file_text: quote_check.file_text,
        file_markdown: quote_check.file_markdown
      )

      unless quote_reader.text&.strip.presence
        add_error("file_reading_error",
                  category: "file",
                  type: "error")
      end
    rescue QuoteReader::NoFileContentError
      add_error("empty_file_error",
                category: "file",
                type: "error")
    rescue QuoteReader::ReadError
      add_error("file_reading_error",
                category: "file",
                type: "error")
    rescue QuoteReader::UnsupportedFileType
      add_error("unsupported_file_format",
                category: "file",
                type: "error")
    ensure
      text = quote_reader.text
      anonymised_text = quote_reader.anonymised_text

      if Llms::Base.include_null_bytes?(text)
        ErrorNotifier.notify(
          StandardError.new("QuoteCheck #{quote_check.id} contains null bytes")
        )
      end
    end

    quote_check.assign_attributes(
      ocr: quote_reader.ocr,

      # Avoid null bytes inside text field to not break PostgreSQL
      # TODO: Better fix null bytes at chore to not have them
      text: Llms::Base.remove_null_bytes(text),
      anonymised_text: Llms::Base.remove_null_bytes(anonymised_text),

      naive_attributes: quote_reader.naive_attributes,
      naive_version: quote_reader.naive_version,

      private_data_qa_attributes: quote_reader.private_data_qa_attributes,
      private_data_qa_result: quote_reader.private_data_qa_result,
      private_data_qa_version: quote_reader.private_data_qa_version,

      qa_attributes: quote_reader.qa_attributes,
      qa_result: quote_reader.qa_result,
      qa_version: quote_reader.qa_version,

      read_attributes: quote_reader.read_attributes
    )

    MdsoApi.new.validate_quote_check!(
      QuoteCheckSerializer.new(quote_check, full: true).as_json.transform_keys(&:to_s)
    )

    quote_check
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # Reset results but keep attributes
  def reset_check
    quote_check.assign_attributes(
      finished_at: nil,

      validation_errors: nil,
      validation_error_details: nil,
      validation_version: nil
    )
  end

  def validate_quote # rubocop:disable Metrics/MethodLength
    quote_validator = QuoteValidator::Global.new(
      quote_check.read_attributes,
      quote_id: quote_check.id
    )
    quote_validator.validate!

    quote_check.assign_attributes(
      validation_controls_count: quote_validator.controls_count,
      validation_errors: quote_validator.errors,
      validation_error_details: quote_validator.error_details,
      validation_version: quote_validator.version
    )
  end
end
