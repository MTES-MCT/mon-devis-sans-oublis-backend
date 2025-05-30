# frozen_string_literal: true

# Check RGE
module RgeValidator
  class ArgumentError < QuoteValidator::Base::ArgumentError; end

  RGE_NUMBER_REGEX = /\d{3,}/

  def self.filter_rge_qualifications(rge_qualifications)
    rge_qualifications.select { it.fetch("nom_certificat").match?(/RGE/i) }
  end

  # TODO: Add optional date parameter
  # rubocop:disable Metrics/AbcSize
  def self.valid?(rge: nil, siret: nil) # rubocop:disable Metrics/MethodLength
    rge = validate_format!(rge) if rge.present?

    if rge.present?
      rge_qualifications = filter_rge_qualifications(
        DataAdeme.new.historique_rge(qs: "siret:#{siret}").fetch("results")
      )
      unless rge_qualifications.any? { it.fetch("_id")[/(#{RGE_NUMBER_REGEX})-/, 1] == rge[/#{RGE_NUMBER_REGEX}\z/] }
        raise ArgumentError.new(nil, "rge_non_correspondant")
      end

      return true
    end

    filter_rge_qualifications(
      DataAdeme.new.historique_rge(qs: "siret:#{siret}").fetch("results")
    ).any?
  end
  # rubocop:enable Metrics/AbcSize

  def self.validate_format!(rge)
    formatted_rge = rge&.gsub(/\s+/, "")&.strip.presence

    raise ArgumentError.new(nil, "rge_manquant") if formatted_rge.blank?
    raise ArgumentError.new(nil, "rge_format_erreur") unless formatted_rge.is_a?(String)

    formatted_rge
  end
end
