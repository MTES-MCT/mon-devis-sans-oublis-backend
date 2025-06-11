# frozen_string_literal: true

# ProcessingLog represents an event on a QuoteCheck.
class ProcessingLog < ApplicationRecord
  belongs_to :processable, polymorphic: true, optional: true

  validate :validate_input
  validates :started_at, presence: true
  validate :finished_after_started

  # In seconds
  def duration
    return nil if finished_at.blank? || started_at.blank?

    (finished_at - started_at).to_f.ceil(2)
  end

  private

  def validate_input
    return if processable
    return if input_parameters.present?

    errors.add(:input_parameters, :blank, message: "doit être présent si pas de processable associé")
  end

  def finished_after_started
    return if finished_at.blank? || started_at.blank?

    return unless finished_at < started_at

    errors.add(:finished_at, :started_at, message: "doit être postérieure à la date de début")
  end
end
