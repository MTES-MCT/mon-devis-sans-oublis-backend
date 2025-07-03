# frozen_string_literal: true

# Edits Quote after analysis, adding some comments for the end-user.
module QuoteCheckEdits
  extend ActiveSupport::Concern

  MAX_COMMENT_LENGTH = 1_000
  MAX_EDITION_REASON_LENGTH = 255
  VALIDATION_ERROR_DELETION_REASONS = %w[
    information_present
    not_used
  ].freeze

  included do
    validates :comment, length: { maximum: MAX_COMMENT_LENGTH }

    before_validation :format_commented_at
    before_validation :format_validation_error_edits
    validate :validation_error_edits_data

    scope :with_edits, -> { where.not(validation_error_edits: nil) }
  end

  def comment_validation_error_detail!(error_id, comment)
    self.validation_error_edits ||= {}
    validation_error_edits[error_id] ||= {}
    validation_error_edits[error_id].merge!(
      "comment" => comment&.presence&.first(MAX_COMMENT_LENGTH),
      "commented_at" => Time.zone.now.iso8601
    )
    self.validation_error_edited_at = validation_error_edits[error_id].fetch("commented_at")

    save!
  end

  def commented?
    comment.present? || commented_at.present? ||
      validation_error_edits&.values&.any? { it.key? "commented_at" } || false
  end

  def delete_validation_error_detail!(error_id, reason: nil)
    self.validation_error_edits ||= {}
    validation_error_edits[error_id] ||= {}
    validation_error_edits[error_id].merge!(
      "deleted" => true,
      "deleted_at" => Time.zone.now.iso8601,
      "reason" => reason&.presence&.first(QuoteCheckEdits::MAX_EDITION_REASON_LENGTH)
    )
    self.validation_error_edited_at = validation_error_edits[error_id].fetch("deleted_at")

    save!
  end

  def edited_at
    (
      [
        validation_error_edited_at,
        commented_at
      ] +
        Array.wrap(validation_error_edits&.values&.flat_map { [it["commented_at"], it["deleted_at"]] }).compact
             .map { Time.zone.parse(it) }
    ).compact.max
  end

  def format_commented_at
    self.commented_at = comment.present? ? Time.zone.now : nil
  end

  def format_validation_error_edits
    self.validation_error_edits = validation_error_edits&.presence
    return unless validation_error_edits

    self.validation_error_edits = JSON.parse(validation_error_edits) if validation_error_edits.is_a?(String)
    self.validation_error_edits = validation_error_edits.transform_values(&:presence).compact # Remove empty values

    validation_error_edits
  end

  def readd_validation_error_detail!(validation_error_id)
    if validation_error_edits&.key?(validation_error_id)
      self.validation_error_edits[validation_error_id] = validation_error_edits[validation_error_id]
                                                         .except("deleted", "deleted_at", "reason").presence
      self.validation_error_edited_at = Time.zone.now
    end

    save!
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def validation_error_edits_data
    return unless validation_error_edits

    validation_error_edits.each do |error_id, edit|
      next unless edit

      unless validation_error_details&.any? { it.fetch("id") == error_id }
        errors.add(:validation_error_edits, "erreur #{error_id} inconnue")
      end

      if edit["reason"] && edit["reason"].length > MAX_EDITION_REASON_LENGTH
        errors.add(:validation_error_edits, "reason in #{error_id} exceeds #{MAX_EDITION_REASON_LENGTH} chars")
      end

      if edit["comment"] && edit["comment"].length > MAX_COMMENT_LENGTH
        errors.add(:validation_error_edits, "comment in #{error_id} exceeds #{MAX_COMMENT_LENGTH} chars")
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize
  end
end
