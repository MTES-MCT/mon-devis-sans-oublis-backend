# frozen_string_literal: true

# Job to validate a QuoteCheck against the RNT (Référentiel National des Travaux)
class QuoteCheckRntValidateJob < ApplicationJob
  queue_as :default

  def perform(quote_check_id)
    return unless QuoteCheck.exists?(quote_check_id)

    RntValidatorService.new(quote_check_id).validate
  end
end
