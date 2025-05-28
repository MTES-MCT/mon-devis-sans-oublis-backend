# frozen_string_literal: true

# Check RGE
module RgeValidator
  class ArgumentError < ArgumentError; end

  RGE_NUMBER_REGEX = /\d{3,}/

  # TODO: Add optional date parameter
  def self.valid?(rge: nil, siret: nil) # rubocop:disable Metrics/AbcSize
    raise ArgumentError, "RGE or SIRET is required" if rge.blank? && siret.blank?
    raise ArgumentError, "RGE must be a string" unless rge.is_a?(String) || rge.nil?

    if rge.present?
      rge_qualifications = DataAdeme.new.historique_rge(qs: "siret:#{siret}").fetch("results")
      return rge_qualifications.any? { it.fetch("_id")[/\A(#{RGE_NUMBER_REGEX})-/, 1] == rge[/#{RGE_NUMBER_REGEX}/] }
    end

    DataAdeme.new.historique_rge(qs: "siret:#{siret}").fetch("results").any?
  end
end
