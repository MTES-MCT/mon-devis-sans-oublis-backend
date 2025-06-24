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
        quote[:type_fichier] != "devis" && quote[:type_fichier] != "facture",
        category: "file",
        type: "error"
      )
    end

    def version
      self.class::VERSION
    end
  end
end
