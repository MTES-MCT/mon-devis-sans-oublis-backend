# frozen_string_literal: true

class ObjectWithValidationSerializer < BaseSerializer
  include ActionView::Helpers::SanitizeHelper

  # Virtual attributes
  attributes :errors, :error_details, :error_messages,
             :control_codes, :controls_count

  def control_codes
    object.validation_control_codes
  end

  def controls_count
    object.validation_controls_count
  end

  def errors
    validation_errors
  end

  def error_details
    validation_error_details&.map do
      it.merge(
        "comment" => sanitize(validation_error_edits&.dig(it["id"], "comment")),
        "deleted" => validation_error_edits&.dig(it["id"], "deleted") || false
      ).compact
    end
  end

  def error_messages
    validation_errors&.index_with do
      I18n.t("quote_validator.errors.#{it}")
    end
  end

  def validation_errors
    validation_error_details&.map { it.fetch("code") }
  end

  def validation_error_details
    @validation_error_details ||= object.validation_error_details&.filter_map do |it|
      it.transform_keys(&:to_s) if it["category"] != "geste_prices"
    end
  end

  def validation_error_edits
    if object.respond_to?(:validation_error_edits)
      object.validation_error_edits
    else
      {}
    end
  end
end
