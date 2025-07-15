# frozen_string_literal: true

# This service checks if a quote check has timed out and updates its status accordingly.
class QuoteCheckTimeout
  attr_reader :quote_check

  def initialize(quote_check)
    @quote_check = quote_check
  end

  # rubocop:disable Metrics/AbcSize
  def check # rubocop:disable Metrics/MethodLength
    validator = QuoteValidator::Timeout.new(
      quote_check.attributes,
      quote_id: quote_check.id
    )
    validator.validate!

    if validator.errors.any?
      quote_check.finished_at = Time.current # Force invalid status

      quote_check.update!(
        validation_control_codes: validator.control_codes,
        validation_controls_count: validator.controls_count,
        validation_errors: validator.errors,
        validation_error_details: validator.error_details,
        validation_version: validator.version
      )
    end

    quote_check
  end
  # rubocop:enable Metrics/AbcSize
end
