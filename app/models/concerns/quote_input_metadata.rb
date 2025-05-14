# frozen_string_literal: true

# Add profile and metadata from user inputs
module QuoteInputMetadata
  extend ActiveSupport::Concern

  PROFILES = %w[artisan particulier conseiller].freeze # Also called Persona
  DEPRECATED_PROFILES = %w[mandataire].freeze

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
    def metadata_values(key)
      key_values = I18n.t("quote_checks.metadata").with_indifferent_access.fetch(key)
      return key_values unless key_values.first.is_a?(Hash)

      key_values.flat_map { it.fetch(:values) }
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
      metadata["gestes"] = # Backport
        metadata["gestes"].map do
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

      key_values = self.class.metadata_values(key)
      errors.add(:metadata, "clé #{key} non autorisée") unless key_values
      values.each do |value|
        errors.add(:metadata, "valeur #{value} non autorisée pour #{key}") unless key_values.include?(value)
      end
    end
  end
end
