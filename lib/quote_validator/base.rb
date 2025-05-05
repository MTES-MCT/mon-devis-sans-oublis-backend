# frozen_string_literal: true

module QuoteValidator
  # Validator for the Quote
  class Base
    class NotImplementedError < ::NotImplementedError; end

    attr_accessor :controls_count, :error_details, :quote, :quote_id, :warnings

    def self.geste_index(quote_id, geste_index)
      [quote_id, "geste", geste_index + 1].compact.join("-")
    end

    # @param [Hash] quote
    # quote is a hash with the following keys
    # - siret: [String] the SIRET number of the company
    def initialize(quote_attributes, quote_id: nil, error_details: nil)
      @quote = TrackingHash.new(quote_attributes)

      @quote_id = quote_id
      @error_details = error_details

      @controls_count = 0
    end

    def self.error_categories
      I18n.t("quote_validator.error_categories").transform_keys(&:to_s)
    end

    def self.error_types
      I18n.t("quote_validator.error_types").transform_keys(&:to_s)
    end

    def add_error_if(code, condition, **)
      increment_controls_count
      return unless condition

      add_error(code, **)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/ParameterLists
    def add_error(code,
                  category: nil, type: nil,
                  title: nil,
                  problem: nil, solution: nil,
                  geste: nil,
                  provided_value: nil,
                  value: nil) # value is DEPRECATED
      provided_value ||= value

      if category && self.class.error_categories.keys.include?(category.to_s)
        e = NotImplementedError.new("Category '#{category}' is not listed")
        ErrorNotifier.notify(e)
      end
      if type && self.class.error_types.keys.include?(type.to_s)
        e = NotImplementedError.new("Type '#{type}' is not listed")
        ErrorNotifier.notify(e)
      end

      geste_id = self.class.geste_index(quote_id, geste[:index]) if geste

      if error_details.any? { |it| it.key?(:geste_id) && it.fetch(:geste_id) == geste_id && it.fetch(:code) == code }
        e = ArgumentError.new("Already error with code '#{code}' for geste_id '#{geste_id}'")
        ErrorNotifier.notify(e)
      end

      error_details << TrackingHash.nilify_empty_values(
        {
          id: [quote_id, error_details.count + 1].compact.join("-"),
          geste_id:,
          code:,
          category:, type:,
          title: title || I18n.t("quote_validator.errors.#{code}"),
          problem:,
          solution: solution || I18n.t("quote_validator.errors.#{code}_infos", default: nil),
          provided_value:
        },
        compact: true
      )
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def errors
      error_details&.map { it.fetch(:code) } || []
    end

    def fields
      quote&.keys_accessed || []
    end

    def increment_controls_count
      @controls_count += 1
    end

    # TODO: doit valider les critères techniques associés aux gestes présents dans le devis
    def validate!
      @error_details = []

      yield

      valid?
    end

    def valid?
      !error_details.nil? && error_details.empty?
    end
  end
end
