# frozen_string_literal: true

# Job to validate a QuoteCheck against the RNT (Référentiel National des Travaux)
class QuoteCheckRntValidateJob < ApplicationJob
  queue_as :default

  def perform(quote_check_id)
    quote_check = QuoteCheck.find_by(id: quote_check_id)
    return unless quote_check

    begin
      rnt_validation = RntValidatorService.new(quote_check_id).validate

      # Save in Redis cache for 1 day to display it.
      Kredis.json("rnt:#{quote_check_id}").tap do |cache_key|
        cache_key.value = rnt_validation
        cache_key.expires_in = 1.day
      end
    rescue RntValidatorService::NotProcessableError => e
      Rails.logger.error("RNT validation failed for QuoteCheck #{quote_check_id}: #{e.message}")
      raise
    end
  end
end
