# frozen_string_literal: true

module QuoteValidator
  # Validator for the Quote
  class Global < Base
    VERSION = "0.0.1"

    def validate!
      super do
        if validate_file # Skip other checks if file not relevant
          validate_admin
          validate_works
          validate_prices
        end
      end
    end

    protected

    def validate_file # rubocop:disable Naming/PredicateMethod
      validator = QuoteValidator::File.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def validate_admin # rubocop:disable Naming/PredicateMethod
      validator = QuoteValidator::Admin.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def validate_works # rubocop:disable Naming/PredicateMethod
      validator = QuoteValidator::Works::Global.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def validate_prices # rubocop:disable Naming/PredicateMethod
      validator = QuoteValidator::Prices.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end
  end
end
