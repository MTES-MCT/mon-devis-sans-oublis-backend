# frozen_string_literal: true

# Edits Quote after analysis, adding some comments for the end-user.
module QuoteCheckEdits # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  MAX_COMMENT_LENGTH = 1_000
  MAX_EDITION_REASON_LENGTH = 255
  VALIDATION_ERROR_DELETION_REASONS = %w[
    information_present
    not_used
  ].freeze

  included do
    before_validation :format_commented_at, if: -> { has_attribute?(:commented_at) }
    validates :comment, length: { maximum: MAX_COMMENT_LENGTH }, if: -> { has_attribute?(:comment) }

    before_validation :format_validation_error_edits
    validate :validation_error_edits_data

    scope :with_edits, -> { where.not(validation_error_edits: nil) }
  end

  def error_id_for_code(error_code)
    validation_error_details.detect do |error_details|
      error_details.fetch("code") == error_code
    end&.fetch("id")
  end

  def comment_validation_error_detail!(error_id, comment) # rubocop:disable Metrics/AbcSize
    self.validation_error_edits ||= {}
    validation_error_edits[error_id] ||= {}
    last_comment = validation_error_edits[error_id]&.fetch("comment", nil)

    validation_error_edits[error_id].merge!(
      "comment" => comment&.presence&.first(MAX_COMMENT_LENGTH),
      "commented_at" => Time.zone.now.iso8601
    )
    self.validation_error_edited_at = validation_error_edits[error_id].fetch("commented_at")

    repercute_comment_validation_error_detail!(error_id, comment, last_comment)

    save!
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def repercute_comment_validation_error_detail!(error_id, comment, last_comment) # rubocop:disable Metrics/MethodLength
    return unless instance_of?(QuotesCase)

    error_code = validation_error_details.detect do |error_details|
      error_details.fetch("id") == error_id
    end.fetch("code")

    quote_checks.each do |quote_check|
      check_error_id = quote_check.error_id_for_code(error_code)
      check_error_details_edit = quote_check.validation_error_edits&.dig(check_error_id)
      next unless check_error_id

      # If the comment has not been overwritten, we add/update it.
      if check_error_details_edit.nil? || check_error_details_edit["comment"] == last_comment
        quote_check.comment_validation_error_detail!(check_error_id, comment)
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def commented? # rubocop:disable Metrics/CyclomaticComplexity
    (has_attribute?(:comment) && comment.present?) ||
      (has_attribute?(:commented_at) && commented_at.present?) ||
      validation_error_edits&.values&.any? { it.key? "commented_at" } || false
  end

  def delete_validation_error_detail!(error_id, reason: nil) # rubocop:disable Metrics/AbcSize
    self.validation_error_edits ||= {}
    validation_error_edits[error_id] ||= {}
    validation_error_edits[error_id].merge!(
      "deleted" => true,
      "deleted_at" => Time.zone.now.iso8601,
      "reason" => reason&.presence&.first(QuoteCheckEdits::MAX_EDITION_REASON_LENGTH)
    )
    self.validation_error_edited_at = validation_error_edits[error_id].fetch("deleted_at")

    repercute_delete_validation_error_detail!(error_id, reason:)

    save!
  end

  def repercute_delete_validation_error_detail!(error_id, reason: nil)
    return unless instance_of?(QuotesCase)

    error_code = validation_error_details.detect do |error_details|
      error_details.fetch("id") == error_id
    end.fetch("code")

    quote_checks.each do |quote_check|
      check_error_id = quote_check.error_id_for_code(error_code)
      quote_check.delete_validation_error_detail!(check_error_id, reason:) if check_error_id
    end
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
    self.commented_at = comment.present? ? Time.zone.now : nil if has_attribute?(:comment)
  end

  def format_validation_error_edits
    self.validation_error_edits = validation_error_edits&.presence
    return unless validation_error_edits

    self.validation_error_edits = JSON.parse(validation_error_edits) if validation_error_edits.is_a?(String)
    self.validation_error_edits = validation_error_edits.transform_values(&:presence).compact # Remove empty values

    validation_error_edits
  end

  def readd_validation_error_detail!(error_id)
    if validation_error_edits&.key?(error_id)
      self.validation_error_edits[error_id] = validation_error_edits[error_id]
                                              .except("deleted", "deleted_at", "reason").presence
      self.validation_error_edited_at = Time.zone.now

      repercute_readd_validation_error_detail!(error_id)
    end

    save!
  end

  def repercute_readd_validation_error_detail!(error_id)
    return unless instance_of?(QuotesCase)

    error_code = validation_error_details.detect do |error_details|
      error_details.fetch("id") == error_id
    end.fetch("code")

    quote_checks.each do |quote_check|
      check_error_id = quote_check.error_id_for_code(error_code)
      quote_check.readd_validation_error_detail!(check_error_id) if check_error_id
    end
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
