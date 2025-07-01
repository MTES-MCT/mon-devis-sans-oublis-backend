# frozen_string_literal: true

# This class is responsible for checking the QuotesCase and returning the result.
class QuotesCaseCheckService
  attr_reader :quotes_case, :save

  def initialize(quotes_case, save: true)
    @quotes_case = quotes_case
    @save = save
  end

  def check
    ErrorNotifier.set_context(:quotes_case, { id: quotes_case.id })

    begin
      reset_check
      validate_quotes_case
      quotes_case.finished_at = Time.current
    ensure
      quotes_case.save! if save
    end

    quotes_case
  end

  # Reset results but keep attributes
  def reset_check
    quotes_case.assign_attributes(
      finished_at: nil,

      validation_errors: nil,
      validation_error_details: nil,
      validation_version: nil
    )
    quotes_case
  end

  private

  # rubocop:disable Metrics/AbcSize
  def validate_quotes_case # rubocop:disable Metrics/MethodLength
    validator = QuoteValidator::QuotesCase.new(
      quotes_case.attributes.merge(
        "quote_checks" => quotes_case.quote_checks.map(&:attributes)
      ),
      quotes_case_id: quotes_case.id
    )
    validator.validate!

    quotes_case.assign_attributes(
      validation_control_codes: validator.control_codes,
      validation_controls_count: validator.controls_count,
      validation_errors: validator.errors,
      validation_error_details: validator.error_details,
      validation_version: validator.version
    )
  end
  # rubocop:enable Metrics/AbcSize
end
