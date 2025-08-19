# frozen_string_literal: true

# Add expectations
module QuoteCheckExpectations
  extend ActiveSupport::Concern

  included do
    validate :expected_validation_errors_as_array, if: -> { expected_validation_errors? }

    scope :with_expected_value, -> { where.not(expected_validation_errors: nil) }
  end

  def expected_validation_errors?
    expected_validation_errors.present?
  end

  def expected_validation_errors_as_array
    return unless expected_validation_errors && !expected_validation_errors.is_a?(Array)

    errors.add(:expected_validation_errors,
               "must be an array")
  end

  def recheckable?
    status != "pending" && (
      expected_validation_errors? ||
      Rails.application.config.app_env != "production" ||
      ocrable?
    )
  end
end
