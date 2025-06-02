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
  # rubocop:disable Metrics/CyclomaticComplexity
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

    rge_qualifications.any?
  end
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
