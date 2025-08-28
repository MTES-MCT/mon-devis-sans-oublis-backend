# frozen_string_literal: true

require "uri"

# Check RGE
module RgeValidator
  class ArgumentError < QuoteValidator::Base::ArgumentError; end

  RGE_NUMBER_REGEX = /\d{3,}/

  def self.filter_rge_qualifications(rge_qualifications)
    rge_qualifications # Consider all as RGE qualifications for now
    # rge_qualifications.select { it.fetch("nom_certificat").match?(/RGE/i) }
  end

  def self.geste_types_for_rge(siret, rge)
    rge_qualifications(siret:, rge:).flat_map do |qualification|
      MdsoAdemeMapping.ademe_geste_types(
        nom_certificat: qualification.fetch("nom_certificat"),
        domaine: qualification.fetch("domaine")
      )
    end.compact.uniq.sort
  end

  # @param rge [String, Array<String>] RGE number(s) to check
  # @param id [String] ADEME RGE ID to check against
  def self.rge_for_id?(rge, id)
    return false if rge.blank? || id.blank?
    return id_to_rge(id) == rge[/#{RGE_NUMBER_REGEX}\z/] if rge.is_a?(String)

    Array.wrap(rge).any? { rge_for_id?(it, id) }
  end

  def self.rge_link
    URI.join(ENV.fetch("FRONTEND_APPLICATION_HOST", nil), "rge").to_s
  end

  def self.id_to_rge(id)
    id[/(#{RGE_NUMBER_REGEX})-/, 1] if id.present?
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Style/ItBlockParameter
  def self.rge_qualifications(rge: nil, siret: nil, date: nil, geste_types: nil) # rubocop:disable Metrics/MethodLength
    qs = "siret:#{SiretValidator.validate_format!(siret)}" if siret.present?
    qs ||= "rge:#{validate_format!(rge)}" if rge.present?
    rge_qualifications = filter_rge_qualifications(
      DataAdeme.new.historique_rge(qs:).fetch("results")
    )

    if rge.present?
      rge_qualifications = rge_qualifications.select { rge_for_id?(rge, it.fetch("_id")) }
      raise ArgumentError.new(nil, "rge_non_correspondant") unless rge_qualifications.any?
    end

    if geste_types.present?
      rge_qualifications = rge_qualifications.select do
        MdsoAdemeMapping.ademe_geste_types(
          nom_certificat: it.fetch("nom_certificat"),
          domaine: it.fetch("domaine")
        ).intersect?(geste_types)
      end
    end

    # Date check in the end to raise rge_hors_date specific error
    if date.present?
      rge_qualifications = rge_qualifications.select do
        date.between?(Date.parse(it.fetch("date_debut")), Date.parse(it.fetch("date_fin")))
      end
      raise ArgumentError.new(nil, "rge_hors_date") if rge_qualifications.empty? && rge.present?
    end

    rge_qualifications
  end
  # rubocop:enable Style/ItBlockParameter
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # @return [Array, false] Returns an array of RGE qualifications or false if none found.
  # @raise [ArgumentError] Raises an error if the RGE format is invalid or if the date is not in the correct format.
  def self.valid?(rge: nil, siret: nil, date: nil, geste_types: nil)
    date = validate_date!(date) if date.present?
    rge = validate_format!(rge) if rge.present?
    raise ArgumentError.new(nil, "rge_siret_manquant") if rge.blank? && siret.blank?

    geste_types = Array.wrap(geste_types).presence&.uniq
    unknown_geste_types = geste_types - GesteTypes::VALUES if geste_types.present?
    raise ArgumentError.new(nil, "geste_type_inconnu") if unknown_geste_types&.any?

    filtered_rge_qualifications = rge_qualifications(rge:, siret:, date:, geste_types:)
    filtered_rge_qualifications.any? ? filtered_rge_qualifications : false
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def self.validate_date!(date)
    return if date.blank?

    begin
      Date.parse(date)
    rescue Date::Error
      raise ArgumentError.new(nil, "date_format_erreur")
    end
  end

  # Format and raise errors on wrong format

  def self.validate_format!(rge)
    formatted_rge = rge&.gsub(/\s+/, "")&.strip.presence

    raise ArgumentError.new(nil, "rge_manquant") if formatted_rge.blank?
    raise ArgumentError.new(nil, "rge_format_erreur") unless formatted_rge.is_a?(String)

    formatted_rge
  end
end
