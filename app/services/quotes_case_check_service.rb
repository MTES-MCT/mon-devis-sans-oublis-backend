# frozen_string_literal: true

# This class is responsible for checking the QuotesCase and returning the result.
class QuotesCaseCheckService
  attr_reader :quotes_case, :save

  def initialize(quotes_case, save: true)
    @quotes_case = quotes_case
    @save = save
  end

  # rubocop:disable Metrics/AbcSize
  def check
    ErrorNotifier.set_context(:quotes_case, { id: quotes_case.id })

    begin
      reset_check
      validate_quotes_case
      quotes_case.finished_at = Time.current
    ensure
      quotes_case.save! if save
    end

    QuotesCaseMailer.results_available(quotes_case).deliver_later if quotes_case.email

    quotes_case
  end
  # rubocop:enable Metrics/AbcSize

  # Reset results but keep attributes
  def reset_check
    reset_quotes_check!

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
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def reset_quotes_check! # rubocop:disable Metrics/MethodLength
    quotes_case.quote_checks.each do |quote_check|
      validation_error_detail_id_to_remove = (quote_check.validation_error_details || []).filter_map do # rubocop:disable Style/ItBlockParameter
        it.fetch("id") if it.fetch("category") == "case_incoherence"
      end

      quote_check.update!(
        validation_controls_count: quote_check.validation_controls_count && quotes_case.validation_controls_count &&
        (quote_check.validation_controls_count - quotes_case.validation_controls_count),
        validation_control_codes: quote_check.validation_control_codes && quotes_case.validation_control_codes &&
        (quote_check.validation_control_codes - quotes_case.validation_control_codes),
        validation_error_details: quote_check.validation_error_details&.reject do # rubocop:disable Style/ItBlockParameter
          validation_error_detail_id_to_remove.include?(it.fetch("id"))
        end,
        validation_error_edits: quote_check.validation_error_edits&.except(*validation_error_detail_id_to_remove)
      )
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

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
