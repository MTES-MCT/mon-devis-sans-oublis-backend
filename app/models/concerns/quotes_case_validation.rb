# frozen_string_literal: true

# Add QuotesCase validation
module QuotesCaseValidation
  extend ActiveSupport::Concern

  included do
    attr_accessor :validation_control_codes, :validation_controls_count,
                  :validation_errors, :validation_error_details,
                  :validation_version
  end

  # Validates the QuotesCase attributes
  # and sets the validation virtual attributes.
  def custom_validate! # rubocop:disable Metrics/MethodLength
    @validation_control_codes = 0
    @validation_controls_count = 0

    @validation_errors = []
    @validation_error_details = []

    validator = QuotesCaseValidator.new(
      attributes.merge("quote_checks" => quote_checks.map(&:attributes)),
      quotes_case_id: id
    )
    validator.validate!

    # TODO: Record in database
    # quotes_case.assign_attributes(
    #   validation_control_codes: validator.control_codes,
    #   validation_controls_count: validator.controls_count,
    #   validation_errors: validator.errors,
    #   validation_error_details: validator.error_details,
    #   validation_version: validator.version
    # )
    @validation_control_codes = validator.control_codes
    @validation_controls_count = validator.controls_count
    @validation_errors = validator.errors
    @validation_error_details = validator.error_details
    @validation_version = validator.version
  end
end
