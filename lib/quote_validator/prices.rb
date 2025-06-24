# frozen_string_literal: true

module QuoteValidator
  # Validator for the QuoteCheck Prices
  class Prices < Base
    VERSION = "0.0.1"

    def self.gestes_prices_ranges(env = nil)
      return @gestes_prices_ranges if defined?(@gestes_prices_ranges) && !env

      # In the JSON stringified format '{ "geste": "12..34" }'
      # HT = Hors Taxe, without VAT taxes
      @gestes_prices_ranges = JSON.parse(
        env || ENV.fetch("MDSO_GESTE_PRICES_RANGES", "{}")
      ).transform_values do |range_str|
        parse_generic_range(range_str)
      end.freeze
    end

    def self.parse_generic_range(str)
      parts = str.split("..")
      raise ArgumentError, "Invalid range format for #{str}" unless parts.size == 2

      Range.new(Integer(parts[0]), Integer(parts[1]))
    end

    def validate!
      super do
        validate_quote_check_prices if self.class.gestes_prices_ranges.any?
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def validate_quote_check_prices # rubocop:disable Metrics/MethodLength
      gestes = quote[:gestes] || []
      gestes.each_with_index do |geste, index|
        geste[:index] = index

        geste_type = geste[:type].to_s
        next unless self.class.gestes_prices_ranges.key?(geste_type)

        price = case geste_type
                when "isolation_comble_perdu", "geste_unite_m2"
                  if geste[:prix_unitaire_ht] ||
                     geste[:quantite]
                    ((geste[:prix_ht] || geste[:prix_total_ht]) / geste[:quantite])
                  end
                else
                  geste[:prix_total_ht]
                end
        next if price.nil? || price.zero?

        add_error_if(
          "geste_prix_inhabituel",
          self.class.gestes_prices_ranges[geste_type].exclude?(price),
          geste,
          provided_value: price
        )
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def add_error_if(code, condition, geste, category: "geste_prices", type: "warning", provided_value: nil)
      super(code, condition,
                type:,
                category:,
                geste:,
                provided_value:)
    end

    def version
      self.class::VERSION
    end
  end
end
