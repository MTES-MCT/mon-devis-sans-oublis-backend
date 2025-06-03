# frozen_string_literal: true

class QuotesCaseSerializer < BaseSerializer
  attributes :id, :reference, :status
  has_many :quote_checks, serializer: QuoteCheckInsideCaseSerializer
end
