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

    def validate_file
      validator = QuoteValidator::File.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def validate_admin
      validator = QuoteValidator::Admin.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def validate_works
      validator = QuoteValidator::Works::Global.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def validate_prices
      validator = QuoteValidator::Prices.new(quote, quote_id:)
      validator.validate!
      add_validator_errors(validator)
      validator.error_details.empty?
    end

    def version
      self.class::VERSION
    end
  end
end
