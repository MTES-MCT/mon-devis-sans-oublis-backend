# frozen_string_literal: true

# Store user feedback for a quote check
class QuoteCheckFeedback < ApplicationRecord
  belongs_to :quote_check

  strip_attributes

  # Global feedback
  validates :rating,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 },
            if: -> { global? }

  # Detail feedback
  validates :validation_error_details_id, presence: true, if: -> { rating.blank? }
  validates :comment, presence: true, if: -> { !global? }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :comment, length: { maximum: 1_000 }

  before_validation :check_validation_error_details_id, if: -> { !global? }

  def global?
    validation_error_details_id.blank?
  end

  def provided_value
    validation_error_details&.dig("provided_value")
  end

  def validation_error_details
    return unless validation_error_details_id

    quote_check.validation_error_details.find { it.fetch("id") == validation_error_details_id }
  end

  private

  def check_validation_error_details_id
    return if quote_check&.validation_error_details&.any? { it.fetch("id") == validation_error_details_id }

    errors.add(:validation_error_details_id, "is invalid")
  end
end
