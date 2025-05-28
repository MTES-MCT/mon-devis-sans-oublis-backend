# frozen_string_literal: true

# Check SIRET
module SiretValidator
  class ArgumentError < ArgumentError; end

  # TODO: Add optional date parameter
  def self.valid?(siret)
    raise BadFormat, "SIRET is required" if siret.blank?
    raise BadFormat, "SIRET must be 14 digits" unless siret.match?(QuoteReader::NaiveText::SIRET_REGEX)

    SireneApi.new.recherche(siret)
  end
end
