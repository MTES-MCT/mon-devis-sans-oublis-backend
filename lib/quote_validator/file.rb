# frozen_string_literal: true

module QuoteValidator
  # Validator for the Quote
  class File < Base
    VERSION = "0.0.1"

    def validate!
      super do
        validate
      end
    end

    def validate
      add_error_if(
        "file_type_error",
        %w[devis facture].exclude?(quote[:type_fichier]),
        category: "file",
        type: "error"
      )
    end

    def version
      self.class::VERSION
    end
  end
end
