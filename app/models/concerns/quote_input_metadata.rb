# frozen_string_literal: true

# Add profile and metadata from user inputs
module QuoteInputMetadata # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  PROFILES = %w[artisan particulier conseiller].freeze # Also called Persona
  DEPRECATED_PROFILES = %w[mandataire].freeze

  # Complete list of Geste types from QA prompts
  GESTE_TYPES_GROUPS = {
    "Chauffage" => %w[
      chaudiere_biomasse
      systeme_solaire_combine
      poele_insert
      pac_air_air
      pac_air_eau
      pac_hybride
      pac_eau_eau
    ],
    "Eau chaude sanitaire" => %w[
      chauffe_eau_solaire_individuel
      chauffe_eau_thermo
    ],
    "Isolation" => %w[
      isolation_thermique_par_exterieur_ITE
      isolation_thermique_par_interieur_ITI
      isolation_comble_perdu
      isolation_rampants_toiture
      isolation_toiture_terrasse
      isolation_plancher_bas
    ],
    "Menuiserie" => %w[
      menuiserie_fenetre
      menuiserie_volet_isolant
      menuiserie_fenetre_toit
      menuiserie_porte
    ],
    "Ventilation" => %w[
      vmc_double_flux
      vmc_simple_flux
    ]
  }.freeze
  GESTE_TYPES = GESTE_TYPES_GROUPS.values.flatten.freeze

  RENOVATION_TYPES = %w[geste ampleur].freeze

  included do
    validates :source_name, presence: true
    validates :profile, presence: true, inclusion: { in: PROFILES + DEPRECATED_PROFILES }

    validates :renovation_type, presence: true, inclusion: { in: RENOVATION_TYPES }

    before_validation :format_metadata
    validate :metadata_data

    scope :accessible_for_source, lambda { |source_name|
      where(source_name: source_name&.downcase) unless source_name&.downcase == "mdso"
    }
  end

  class_methods do
    def metadata_values_for(key)
      key_values = I18n.t("quote_checks.metadata").with_indifferent_access.fetch(key)
      return key_values unless key_values.first.is_a?(Hash)

      key_values.flat_map { it.fetch(:values) }
    end

    def metadata_values
      I18n.t("quote_checks.metadata").with_indifferent_access
    end
  end

  def aides
    metadata&.fetch("aides", [])
  end

  def aides=(values)
    self.metadata ||= {}
    self.metadata["aides"] = values&.filter(&:presence).presence
    self.metadata.presence
  end

  def gestes
    metadata&.fetch("gestes", [])
  end

  def gestes=(values)
    self.metadata ||= {}
    self.metadata["gestes"] = values&.filter(&:presence).presence
    self.metadata.presence
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def format_metadata # rubocop:disable Metrics/MethodLength
    self.renovation_type = renovation_type&.presence
    self.renovation_type ||= self.case&.renovation_type if has_attribute?(:case_id)

    self.reference = reference&.presence

    self.metadata = metadata&.presence
    self.metadata ||= self.case&.metadata if has_attribute?(:case_id)
    return unless metadata

    self.metadata = JSON.parse(metadata) if metadata.is_a?(String)
    self.metadata = metadata.transform_values(&:presence).compact # Remove empty values

    if metadata&.key?("gestes")
      metadata["gestes"] = # TODO: remove this Backport after fixing the frontend and database
        metadata["gestes"].map do # rubocop:disable Style/ItBlockParameter
          it.gsub("Poêle à granulés", "Poêle/insert à bois/granulés")
        end
    end

    metadata
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def metadata_data
    return unless metadata

    metadata.each do |key, values|
      next unless values

      key_values = self.class.metadata_values_for(key)
      errors.add(:metadata, "clé #{key} non autorisée") unless key_values
      values.each do |value|
        errors.add(:metadata, "valeur #{value} non autorisée pour #{key}") unless key_values.include?(value)
      end
    end
  end
end
