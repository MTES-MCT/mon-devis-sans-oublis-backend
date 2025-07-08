# frozen_string_literal: true

class QuotesCaseSerializer < ObjectWithValidationSerializer
  attributes :id, :reference,
             :status,
             :started_at, :finished_at

  has_many :quote_checks, serializer: QuoteCheckInsideCaseSerializer, if: :quote_checks

  def quote_checks
    object.quote_checks.order(created_at: :desc).presence
  end
end
