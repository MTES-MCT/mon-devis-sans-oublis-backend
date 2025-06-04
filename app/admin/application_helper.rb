# frozen_string_literal: true

module ActiveAdmin
  # Specialized view helpers for ActiveAdmin
  module ViewHelpers
    def geste_errors(quote_check, geste_index)
      geste_id = QuoteValidator::Base.geste_index(
        quote_check.id, geste_index
      )
      quote_check.validation_error_details&.select { |error| error["geste_id"] == geste_id }
    end

    def local_time(time)
      time&.in_time_zone("Europe/Paris")&.strftime("%d/%m/%Y %H:%M")
    end
  end
end
