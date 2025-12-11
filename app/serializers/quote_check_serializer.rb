# frozen_string_literal: true

class QuoteCheckSerializer < ObjectWithValidationSerializer
  include ActionView::Helpers::SanitizeHelper

  attributes :id, :status, :profile,
             :reference, :metadata,
             # :parent_id,
             :filename,
             :gestes,
             :started_at, :finished_at,
             :comment,
             :gestes,
             :result_link

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

  def filename
    # Avoid N+1 queries or reduce their sizes
    if object.association(:file).loaded?
      object.filename
    elsif object.file_id.present?
      QuoteFile.select(:filename).find_by(id: object.file_id)&.filename
    end
  end

  def gestes # rubocop:disable Metrics/MethodLength
    object.read_attributes&.fetch("gestes", nil)&.map&.with_index do |geste, geste_index| # rubocop:disable Style/SafeNavigationChainLength
      geste_id = QuoteValidator::Base.geste_index(object.id, geste_index)
      {
        "id" => geste_id,
        "intitule" => "#{geste['numero_ligne']} #{geste['intitule']}",
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

  def result_link
    object.frontend_webapp_url(mtm_campaign: "api")
  end
end
