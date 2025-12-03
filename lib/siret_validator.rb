# frozen_string_literal: true

# Check SIRET
module SiretValidator
  class ArgumentError < QuoteValidator::Base::ArgumentError; end

  SIRET_VALID = "11006801200050" # MTE

  # TODO: Add optional date parameter
  # Boolean check if SIRET is valid, raise ArgumentError on wrong format
  def self.valid?(siret)
    # TODO: Use API Entreprise instead
    SireneApi.new.recherche(validate_format!(siret)) ||
      SireneApi.new.recherche(SIRET_VALID) == false
  end

  # Format and raise errors on wrong format
  def self.validate_format!(siret)
    formatted_siret = siret&.gsub(/\s+/, "")&.strip.presence

    raise ArgumentError.new(nil, "siret_manquant") if formatted_siret.blank?

    unless formatted_siret.match?(QuoteReader::NaiveText::SIRET_REGEX)
      raise ArgumentError.new(nil,
                              "siret_format_erreur")
    end

    formatted_siret
  end
end
