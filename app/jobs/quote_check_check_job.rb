# frozen_string_literal: true

# Job to (re)check an existing QuoteCheck
class QuoteCheckCheckJob < ApplicationJob
  queue_as :critical

  def perform(quote_check_id, force_ocr: nil, ocr: nil, qa_llm: nil)
    quote_check = QuoteCheck.find_by(id: quote_check_id)
    return unless quote_check

    force_ocr = quote_check.force_ocr if force_ocr.nil?
    ocr ||= quote_check.ocr
    qa_llm ||= quote_check.qa_llm

    QuoteCheckService.new(quote_check).check(force_ocr:, ocr:, qa_llm:)
  end
end
