# frozen_string_literal: true

# Add post case data
module QuotesCasePostCheckMetadata
  extend ActiveSupport::Concern

  included do
    STATUSES = QuoteCheck::STATUSES # rubocop:disable Lint/ConstantDefinitionInBlock
  end

  # Returns a float number in €
  def cost
    return unless quote_checks.any?

    quote_checks.filter_map(&:cost).sum
  end

  def processing_time
    return unless finished_at

    finished_at - started_at
  end

  # valid? is already used by the framework
  def quotes_case_valid?
    status == "valid"
  end

  def started_at
    quote_checks.minimum(:started_at)
  end

  def finished_at
    read_attribute(:finished_at) ||
      quote_checks.maximum(:finished_at)
  end

  # pending if any quote_check is pending
  # valid if all quote_checks are valid
  # else invalid
  def status
    return unless quote_checks.any?

    return "pending" if quote_checks.any? { it.status == "pending" } ||
                        finished_at.nil?

    quote_checks.all?(&:quote_valid?) ? "valid" : "invalid"
  end
end
