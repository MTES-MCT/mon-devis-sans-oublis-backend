# frozen_string_literal: true

# Job to (re)check an existing QuoteCheck
class QuoteCheckCheckJob < ApplicationJob
  queue_as :default

  def perform(quote_check_id, ocr: nil, qa_llm: nil)
    quote_check = QuoteCheck.find(quote_check_id)

    ocr ||= quote_check.ocr
    qa_llm ||= quote_check.qa_llm
    QuoteCheckService.new(quote_check).check(ocr:, qa_llm:)
  end
end
