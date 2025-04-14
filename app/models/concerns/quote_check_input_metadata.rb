# frozen_string_literal: true

# Add profile and metadata from user inputs
module QuoteCheckInputMetadata
  extend ActiveSupport::Concern

  PROFILES = %w[artisan particulier conseiller].freeze # Also called Persona
  DEPRECATED_PROFILES = %w[mandataire].freeze

  included do
    validates :profile, presence: true, inclusion: { in: PROFILES + DEPRECATED_PROFILES }

    before_validation :format_metadata
    validate :metadata_data
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
  # rubocop:disable Metrics/MethodLength
  def format_metadata
    self.metadata = metadata&.presence
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
  # rubocop:enable Metrics/MethodLength
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
