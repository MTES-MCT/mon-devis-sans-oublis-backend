# frozen_string_literal: true

# Add QuotesCase validation
module QuotesCaseValidation
  extend ActiveSupport::Concern

  included do
    attr_accessor :validation_control_codes, :validation_controls_count,
                  :validation_errors, :validation_error_details,
                  :validation_version
  end
end
