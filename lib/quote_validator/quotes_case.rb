# frozen_string_literal: true

require 'fuzzystringmatch' # rubocop:disable Style/StringLiterals

module QuoteValidator
  # Validator for the QuotesCase
  class QuotesCase < Base
    VERSION = "0.0.1"

    def validate!
      super do
        validate_quote_checks_coherence if quotes_case[:quote_checks] && quotes_case[:quote_checks].size > 1
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Style/ItBlockParameter
    def validate_quote_checks_coherence # rubocop:disable Metrics/MethodLength
      add_error_if(
        "client_prenom_incoherent",
        arrays_intersect(quotes_case[:quote_checks].map do
          Array.wrap(it.dig(:read_attributes, :client_prenoms))
        end).empty?
      )
      add_error_if(
        "client_nom_incoherent",
        arrays_intersect(quotes_case[:quote_checks].map do
          Array.wrap(it.dig(:read_attributes, :client_noms_de_famille))
        end).empty?
      )
      add_error_if(
        "client_adresse_incoherent",
        arrays_intersect(quotes_case[:quote_checks].map do
          Array.wrap(it.dig(:read_attributes, :client_adresses))
        end).empty?
      )
    end
    # rubocop:enable Style/ItBlockParameter
    # rubocop:enable Metrics/AbcSize

    def add_error_if(code, condition, category: "case_incoherence", type: "error")
      super(code, condition,
                type:,
                category:)
    end

    def version
      self.class::VERSION
    end

    private

    def arrays_intersect(arrays, threshold: 0.90)
      jarow = FuzzyStringMatch::JaroWinkler.create(:pure) # Ruby version
      arrays.reduce do |common, current|
        common.select do |item_a|
          current.any? { |item_b| jarow.getDistance(item_a, item_b) > threshold }
        end
      end
    end
  end
end
