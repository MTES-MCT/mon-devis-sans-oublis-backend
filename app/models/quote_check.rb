# frozen_string_literal: true

# QuoteCheck represents a submission of a quote to be checked.
class QuoteCheck < ApplicationRecord
  include ProcessingLogs
  include QuoteCheckBackoffice
  include QuoteCheckEdits
  include QuoteCheckExpectations
  include QuoteCheckFeedbacks
  include QuoteCheckPostCheckMetadata
  include QuoteInputMetadata

  belongs_to :file, class_name: "QuoteFile"
  belongs_to :case, class_name: "QuotesCase", optional: true

  belongs_to :parent, class_name: "QuoteCheck", optional: true
  has_many :children, class_name: "QuoteCheck", foreign_key: :parent_id, inverse_of: :parent, dependent: :nullify

  after_initialize :set_application_version
  strip_attributes

  validates :started_at, presence: true
  validate :validation_errors_as_array, if: -> { validation_errors.present? || validation_error_details.present? }

  validates_associated :case, if: -> { self.case.present? }

  delegate :filename, to: :file, allow_nil: true

  scope :default_order, -> { order(created_at: :desc) }
  scope :with_file_error, -> { where("validation_error_details @> ?", [{ "category" => "file" }].to_json) }
  scope :with_file_type_error, -> { where("validation_error_details @> ?", [{ "code" => "file_type_error" }].to_json) }
  scope :with_price_error, -> { where("validation_error_details @> ?", [{ "category" => "geste_prices" }].to_json) }

  def set_application_version
    self.application_version = Rails.application.config.application_version
  end

  def validation_errors_as_array
    errors.add(:validation_errors, "must be an array") if validation_errors && !validation_errors.is_a?(Array)
    return unless validation_error_details && !validation_error_details.is_a?(Array)

    errors.add(:validation_error_details, "must be an array")
  end
end
