# frozen_string_literal: true

# Job to (re)check an existing QuoteCheck
class QuoteCheckCheckJob < ApplicationJob
  queue_as :critical

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def perform( # rubocop:disable Metrics/MethodLength
    quote_check_id,
    force_ocr: nil, ocr: nil,
    private_data_qa_llm: nil, qa_llm: nil
  )
    quote_check = QuoteCheck.find_by(id: quote_check_id)
    return unless quote_check

    force_ocr = quote_check.force_ocr if force_ocr.nil?
    ocr ||= quote_check.ocr

    private_data_qa_llm ||= quote_check.private_data_qa_llm
    qa_llm ||= quote_check.works_data_qa_llm

    check_args = {
      force_ocr:, ocr:,
      private_data_qa_llm:, qa_llm:
    }

    validation = QuoteCheckService.new(quote_check)
    updated_quote_check = validation.check(**check_args)

    # Fallback to OCR
    if !force_ocr && updated_quote_check.ocrable? &&
       (updated_quote_check.text.nil? || updated_quote_check.text.size < QuoteCheck::OCRABLE_UNDER_CARACTERS_COUNT)
      updated_quote_check.update!(force_ocr: true)
      force_ocr_check_args = check_args.merge(force_ocr: true)
      updated_quote_check = validation.check(**force_ocr_check_args)
    end

    updated_quote_check
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
end
