# frozen_string_literal: true

module QuoteValidator
  # Validator for the Quote
  class Timeout < Base
    VERSION = "0.0.1"

    TIMEOUT_FOR_PROCESSING = Integer(ENV.fetch("MDSO_TIMEOUT_FOR_PROCESSING", 15)).minutes

    def validate!
      super do
        validate
      end
    end

    def version
      self.class::VERSION
    end

    protected

    def consider_timeout?
      object[:started_at] < TIMEOUT_FOR_PROCESSING.ago && object[:finished_at].nil?
    end

    def validate
      return unless consider_timeout?

      add_error(
        "server_timeout_error",
        category: "server",
        type: "error"
      )
    end
  end
end
