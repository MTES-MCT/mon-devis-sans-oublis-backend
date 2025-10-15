# frozen_string_literal: true

class QuotesCaseSerializer < ObjectWithValidationSerializer
  attributes :id, :reference,
             :status,
             :started_at, :finished_at,
             :result_link

  has_many :quote_checks, serializer: QuoteCheckInsideCaseSerializer, if: :quote_checks

  def quote_checks
    object.quote_checks.order(created_at: :desc).presence
  end

  def result_link
    object.frontend_webapp_url(mtm_campaign: "api")
  end
end
