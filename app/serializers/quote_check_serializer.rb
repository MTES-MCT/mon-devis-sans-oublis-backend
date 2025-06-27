# frozen_string_literal: true

class QuoteCheckSerializer < ObjectWithValidationSerializer
  include ActionView::Helpers::SanitizeHelper

  TIMEOUT_FOR_PROCESSING = Integer(ENV.fetch("MDSO_TIMEOUT_FOR_PROCESSING", 15)).minutes

  attributes :id, :status, :profile,
             :reference, :metadata,
             :parent_id,
             :filename,
             :gestes,
             :started_at, :finished_at,
             :comment,
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

  def gestes # rubocop:disable Metrics/MethodLength
    object.read_attributes&.fetch("gestes", nil)&.map&.with_index do |geste, geste_index| # rubocop:disable Style/SafeNavigationChainLength
      geste_id = QuoteValidator::Base.geste_index(object.id, geste_index)
      {
        "intitule" => "#{geste['numero_ligne']} #{geste['intitule']}",
        "id" => geste_id,
        "valid" =>
          validation_error_details.nil? || validation_error_details.none? do # rubocop:disable Style/ItBlockParameter
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
                                    super
                                  end
  end
end
