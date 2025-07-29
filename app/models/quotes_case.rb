# frozen_string_literal: true

# This class is responsible for managing the quote files in a same case.
class QuotesCase < ApplicationRecord
  include ProcessingLogs
  include QuoteInputMetadata
  include QuotesCaseBackoffice
  include QuotesCasePostCheckMetadata

  MAX_QUOTE_CHECKS = 20
  has_many :quote_checks, inverse_of: :case, dependent: :destroy
  validate :quote_checks_count_within_limit

  private

  def quote_checks_count_within_limit
    return if quote_checks.empty? || quote_checks.size <= MAX_QUOTE_CHECKS

    errors.add(:quote_checks, "exceeds the maximum of #{MAX_QUOTE_CHECKS}")
  end
end
