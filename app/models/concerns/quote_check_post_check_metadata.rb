# frozen_string_literal: true

# Add post check data
module QuoteCheckPostCheckMetadata
  extend ActiveSupport::Concern

  included do
    attr_writer :ocr, :qa_llm

    scope :with_valid_processing_time, lambda {
      where.not(finished_at: nil)
           .where("finished_at - started_at > ? AND finished_at - started_at < ?", 0, 1_000.seconds.to_i)
    }
  end

  # Returns a float number in €
  def cost
    return unless qa_result&.key?("usage")

    usage = qa_result.fetch("usage")
    Llms::Mistral.usage_cost_price(
      completion_tokens: usage.fetch("completion_tokens"),
      prompt_tokens: usage.fetch("prompt_tokens")
    )
  end

  def ocr
    @ocr ||= QuoteReader::Global::DEFAULT_OCR # TODO: save in a field
  end

  def processing_time
    return unless finished_at

    finished_at - started_at
  end

  def qa_llm
    @qa_llm ||= case qa_result&.dig("id")
                when /\Achatcmpl-/
                  "Albert"
                else
                  "Mistral" if qa_model&.start_with?("mistral-")
                end
  end

  def qa_model
    qa_result&.dig("model")
  end

  # valid? is already used by the framework
  def quote_valid?
    status == "valid"
  end

  def status
    return "pending" if finished_at.blank?

    validation_errors.blank? ? "valid" : "invalid"
  end

  # Sum of prompt and completion tokens
  def tokens_count
    return unless qa_result&.key?("usage")

    qa_result.fetch("usage").fetch("total_tokens")
  end
end
