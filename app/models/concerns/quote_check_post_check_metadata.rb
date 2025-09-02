# frozen_string_literal: true

# Add post check data
module QuoteCheckPostCheckMetadata
  extend ActiveSupport::Concern

  included do
    delegate :force_ocr, to: :file, allow_nil: true
    delegate :ocr, to: :file, allow_nil: true
    delegate :ocrable?, to: :file, allow_nil: true

    attr_writer :force_ocr, :ocr, :works_data_qa_llm

    STATUSES = %w[pending valid invalid].freeze # rubocop:disable Lint/ConstantDefinitionInBlock

    ransacker :status, type: :string, formatter: proc { |value|
      case value
      when "pending"
        arel_table[:finished_at].eq(nil)
      when "valid"
        arel_table[:finished_at].not_eq(nil).and(arel_table[:validation_errors].eq(nil))
      when "invalid"
        arel_table[:finished_at].not_eq(nil).and(arel_table[:validation_errors].not_eq(nil))
      else
        raise ArgumentError, "Invalid value: #{value}" unless STATUSES.include?(status)
      end
    } do |parent|
      parent.table[:finished_at]
    end
    scope :pending, -> { where(finished_at: nil) }

    VALID_PROCESSING_TIME = 1_000.seconds.to_i # In seconds # rubocop:disable Lint/ConstantDefinitionInBlock
    scope :with_valid_processing_time, lambda {
      where.not(finished_at: nil)
           .where("finished_at - started_at > ? AND finished_at - started_at < ?", 0, VALID_PROCESSING_TIME)
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

  def private_data_qa_llm
    @private_data_qa_llm ||= read_attribute(:private_data_qa_llm) ||
                             Llms::Base.llm_from_result(private_data_qa_result)
  end

  def processing_time
    return unless finished_at

    finished_at - started_at
  end

  def works_data_qa_llm
    @works_data_qa_llm ||= self[:qa_llm] ||
                           Llms::Base.llm_from_result(qa_result)
  end
  alias qa_llm works_data_qa_llm

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
