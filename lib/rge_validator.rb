# frozen_string_literal: true

# Check RGE
module RgeValidator
  class ArgumentError < QuoteValidator::Base::ArgumentError; end

  RGE_NUMBER_REGEX = /\d{3,}/

  # Mapping of ADEME certificate names to MDSO GESTE types
  # See nom_certificat "Libellé du certificat" on https://data.ademe.fr/data-fair/api/v1/datasets/liste-des-entreprises-rge-2/api-docs.json
  # And QA prompts
  ADEME_NOM_CERTIFICAT_TO_MDSO_GESTE_TYPE = {
    "QUALIBAT-RGE" => nil,
    "QualiPAC module Chauffage et ECS" => nil,
    "Certificat OPQIBI" => nil,
    "Tableau de l´Ordre" => nil,
    "Qualibois Eau" => nil,
    "QualiPV 36" => nil,
    "Qualibois Air" => nil,
    "Certificat Qualifelec RGE" => nil,
    "Ventilation +" => nil,
    "Qualisol CESI" => nil,
    "Chauffage +" => %w[chauffe_eau_thermo chauffe_eau_solaire_individuel],
    "QualiPV 500" => nil,
    "Qualisol Combi" => nil,
    "CertiRénov RGE par CERQUAL Qualitel Certification" => nil,
    "QualiPAC module CET" => nil,
    "CERTIBAT-RGE" => nil,
    "AUDIT ENERGETIQUE BATIMENT" => nil,
    "Qualiforage Sonde" => nil,
    "Qualiforage Nappe" => nil,
    "Qualisol Collectif" => nil,
    "RGE Etudes Audits énergétiques Batiments" => nil,
    "CERTIFACT_EUSKADI_EKO" => nil,
    "CERTIFACT_RLB_SQA" => nil,
    "CERTIFICAT_ABCDOMUS" => nil,
    "CERTIFICAT_ADFACTO" => nil,
    "CERTIFICAT_BATIMEX" => nil,
    "CERTIFICAT_BETREC_IG" => nil,
    "CERTIFICAT_BET_PHILIPPE_POULAIN" => nil,
    "CERTIFICAT_CABINET_BAZIN" => nil,
    "CERTIFICAT_CABINET_DENIZOU" => nil,
    "CERTIFICAT_CABINET_HENRI_BRUGNONI_INGENIERIE_HBI" => nil,
    "CERTIFICAT_DPS" => nil,
    "CERTIFICAT_ECHOS" => nil,
    "CERTIFICAT_ECR_HABITAT" => nil,
    "CERTIFICAT_EMIOS" => nil,
    "CERTIFICAT_GBA_CO" => nil,
    "CERTIFICAT_GEXPERTISE" => nil,
    "CERTIFICAT_PLENETUDE" => nil,
    "CERTIFICAT_P_ET_G_PLENETUDE" => nil,
    "CERTIFICAT_SARL_DOMINIQUE_CALLIET" => nil,
    "Certiforage module Sonde" => nil
  }.to_h do |ademe_certificat, mdso_geste_types|
    unkown_geste_types = Array.wrap(mdso_geste_types) - QuoteCheck::GESTE_TYPES
    raise NotImplemented, "Unkown Geste type #{unkown_geste_types}" if unkown_geste_types.any?

    [ademe_certificat, mdso_geste_types]
  end.freeze

  def self.filter_rge_qualifications(rge_qualifications)
    rge_qualifications.select { it.fetch("nom_certificat").match?(/RGE/i) }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # @return [Array, false] Returns an array of RGE qualifications or false if none found.
  # @raise [ArgumentError] Raises an error if the RGE format is invalid or if the date is not in the correct format.
  def self.valid?(rge: nil, siret: nil, date: nil) # rubocop:disable Metrics/MethodLength
    date = validate_date!(date) if date.present?
    rge = validate_format!(rge) if rge.present?

    rge_qualifications = filter_rge_qualifications(
      DataAdeme.new.historique_rge(qs: "siret:#{siret}").fetch("results")
    )

    if rge.present?
      rge_qualifications = rge_qualifications.select do
        it.fetch("_id")[/(#{RGE_NUMBER_REGEX})-/, 1] == rge[/#{RGE_NUMBER_REGEX}\z/]
      end
      raise ArgumentError.new(nil, "rge_non_correspondant") unless rge_qualifications.any?
    end

    if date.present?
      rge_qualifications = rge_qualifications.select do
        date.between?(Date.parse(it.fetch("date_debut")), Date.parse(it.fetch("date_fin")))
      end
      raise ArgumentError.new(nil, "rge_hors_date") if rge_qualifications.empty? && rge.present?
    end

    # TODO: Validate with geste_types with ADEME_NOM_CERTIFICAT_TO_MDSO_GESTE_TYPE

    rge_qualifications.any? ? rge_qualifications : false
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def self.validate_date!(date)
    return if date.blank?

    begin
      Date.parse(date)
    rescue ArgumentError
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
