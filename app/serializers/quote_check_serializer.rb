# frozen_string_literal: true

class QuoteCheckSerializer < BaseSerializer
  include ActionView::Helpers::SanitizeHelper

  TIMEOUT_FOR_PROCESSING = Integer(ENV.fetch("MDSO_TIMEOUT_FOR_PROCESSING", 15)).minutes

  attributes :id, :status, :profile,
             :reference, :metadata,
             :parent_id,
             :filename,
             :gestes,
             :finished_at,
             :comment,
             # Virtual attributes
             :errors, :error_details, :error_messages,
             :control_codes, :controls_count,
             :gestes

  attribute :case_id, if: :full?
  attribute :private_data_qa_attributes, if: :full?
  attribute :qa_attributes, if: :full?
  attribute :read_attributes, if: :full?

  def full?
    instance_options[:full] == true
  end

  def attributes(*args)
    super.compact # Removes keys with nil values
  end

  def comment
    sanitize(object.comment)
  end

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
        "comment" => sanitize(object.validation_error_edits&.dig(it["id"], "comment")),
        "deleted" => object.validation_error_edits&.dig(it["id"], "deleted") || false
      ).compact
    end
  end

  def error_messages
    validation_errors&.index_with do
      I18n.t("quote_validator.errors.#{it}")
    end
  end

  def gestes # rubocop:disable Metrics/MethodLength
    object.read_attributes&.fetch("gestes", nil)&.map&.with_index do |geste, geste_index| # rubocop:disable Style/SafeNavigationChainLength
      geste_id = QuoteValidator::Base.geste_index(object.id, geste_index)
      {
        "intitule" => "#{geste['numero_ligne']} #{geste['intitule']}",
        "id" => geste_id,
        "valid" =>
          validation_error_details.nil? || validation_error_details.none? do
            it["geste_id"] == geste_id
          end
      }
    end
  end

  def finished_at
    format_datetime(object.finished_at)
  end

  def status
    return "invalid" if consider_timeout?

    object.status
  end

  protected

  def consider_timeout?
    object.status == "pending" && object.started_at < TIMEOUT_FOR_PROCESSING.ago
  end

  def validation_errors
    validation_error_details&.map { it.fetch("code") }
  end

  def validation_error_details # rubocop:disable Metrics/MethodLength
    @validation_error_details ||= if consider_timeout?
                                    code = "server_timeout_error"
                                    [{
                                      "id" => [object.id, 1].compact.join("-"),
                                      "code" => code,
                                      "category" => "server", type: "error",
                                      "title" => I18n.t("quote_validator.errors.#{code}")
                                    }]
                                  else
                                    object.validation_error_details&.map do |it|
                                      it.transform_keys(&:to_s)
                                    end
                                  end
  end
end
