# frozen_string_literal: true

# Job to validate a QuoteCheck against the RNT (Référentiel National des Travaux)
class QuoteCheckRntValidateJob < ApplicationJob
  queue_as :default

  def self.cache_key(quote_check_id)
    "rnt:#{quote_check_id}"
  end

  def perform(quote_check_id)
    return unless QuoteCheck.exists?(quote_check_id)

    rnt_validation = RntValidatorService.new(quote_check_id).validate

    # Save in Redis cache for 1 day to display it.
    raise "Kredis not connected" unless kredis_connected?

    Kredis.json(self.class.cache_key(quote_check_id)).tap do |cache_key|
      cache_key.value = rnt_validation
      cache_key.expires_in = 1.day
    end
  end

  private

  def kredis_connected?
    Kredis.redis.ping == "PONG"
  rescue StandardError
    false
  end
end
