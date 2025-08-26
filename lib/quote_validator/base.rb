# frozen_string_literal: true

module QuoteValidator
  # Validator for the Quote
  class Base # rubocop:disable Metrics/ClassLength
    # Custom ArgumentError with error_code
    class ArgumentError < ArgumentError
      attr_reader :error_code

      def initialize(message = nil, error_code = nil)
        message ||= I18n.t("quote_validator.errors.#{error_code}", default: nil)&.strip if error_code

        super(message)

        @error_code = error_code
      end
    end

    class NotImplementedError < ::NotImplementedError; end

    attr_accessor :control_codes, :controls_count,
                  :error_details,
                  :object, :object_id_str,
                  :quote, :quotes_case,
                  :quote_id, :quotes_case_id,
                  :warnings

    def self.geste_index(quote_id, geste_index)
      raise ArgumentError, "geste_index should be an Integer" unless geste_index.is_a?(Integer)

      [quote_id, "geste", geste_index + 1].compact.join("-")
    end

    # @param [Hash] attributes
    # attributes is a hash with the following keys
    # - siret: [String] the SIRET number of the company
    def initialize(attributes, quote_id: nil, quotes_case_id: nil) # rubocop:disable Metrics/MethodLength
      @object = TrackingHash.new(attributes)

      if quote_id && quotes_case_id
        raise ArgumentError, "either quote_id or quotes_case_id must be provided but not both"
      end

      @quote_id = quote_id
      @quotes_case_id = quotes_case_id
      if quotes_case_id
        @quotes_case = @object
      else
        @quote = @object
      end

      @object_id_str = @object[:id] || @quote_id || @quotes_case_id

      reset_errors
    end

    # @return [Hash] error categories with their translations
    def self.error_categories
      I18n.t("quote_validator.error_categories").transform_keys(&:to_s)
    end

    # @return [Hash] error codes with their translations
    def self.error_codes
      I18n.t("quote_validator.errors").transform_keys(&:to_s).except { it.match?(/_infos$/) }
    end

    # @return [Hash] error types with their translations, e.g. { "missing" => "Missing", "wrong" => "Wrong value" }
    def self.error_types
      I18n.t("quote_validator.error_types").transform_keys(&:to_s)
    end

    def errors
      error_details&.map { it.fetch(:code) } || []
    end

    def fields
      object&.keys_accessed || []
    end

    # TODO: doit valider les critères techniques associés aux gestes présents dans le devis
    def validate! # rubocop:disable Naming/PredicateMethod
      @error_details = []

      @control_codes = []
      @controls_count = 0

      yield

      valid?
    end

    def valid?
      !error_details.nil? && error_details.empty?
    end

    def version
      self.class::VERSION
    end

    protected

    def add_error_if(code, condition, **)
      control_codes << code.to_s

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
                  from_case: false,
                  geste: nil,
                  provided_value: nil,
                  value: nil) # value is DEPRECATED
      raise NotImplementedError, "Code '#{code}' is not listed" unless self.class.error_codes.keys.include?(code&.to_s)

      provided_value ||= value

      if category && self.class.error_categories.keys.exclude?(category.to_s)
        e = NotImplementedError.new("Category '#{category}' is not listed")
        ErrorNotifier.notify(e)
      end
      if type && self.class.error_types.keys.exclude?(type.to_s)
        e = NotImplementedError.new("Type '#{type}' is not listed")
        ErrorNotifier.notify(e)
      end

      geste_id = self.class.geste_index(quote_id, geste[:index]) if geste

      if error_details.any? { it.key?(:geste_id) && it.fetch(:geste_id) == geste_id && it.fetch(:code) == code }
        e = ArgumentError.new("Already error with code '#{code}' for geste_id '#{geste_id}'")
        ErrorNotifier.notify(e)
      end

      rge_link_uri = RgeValidator.rge_link if code.to_s.include?("rge")
      solution ||= I18n.t("quote_validator.errors.#{code}_infos_html",
                          default: nil,
                          rge_link: rge_link_uri && ApplicationController.helpers.link_to(rge_link_uri,
                                                                                          rge_link_uri)) ||
                   I18n.t("quote_validator.errors.#{code}_infos", default: nil)

      error_details << TrackingHash.nilify_empty_values(
        {
          id: [object_id_str, geste_id, error_details.count + 1].compact.join("-"),
          from_case:,
          geste_id:,
          code:,
          category:, type:,
          title: (title || I18n.t("quote_validator.errors.#{code}"))&.strip,
          problem:,
          solution: solution&.strip,
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

    # rubocop:disable Metrics/AbcSize
    def add_validator_errors(*validator_or_validators)
      Array.wrap(validator_or_validators.flatten).each do |validator|
        error_details.concat(validator.error_details) if validator.error_details.present?
        control_codes.concat(validator.control_codes) if validator.control_codes.present?
        increment_controls_count(validator.controls_count) if validator.controls_count.present?
      end
    end
    # rubocop:enable Metrics/AbcSize

    def increment_controls_count(increment = 1)
      @controls_count += increment
    end

    def reset_errors
      @error_details = []
      @control_codes = []
      @controls_count = 0
    end
  end
end
