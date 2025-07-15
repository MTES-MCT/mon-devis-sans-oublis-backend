# frozen_string_literal: true

# This job checks if some QuoteChecks has timed out and processes it accordingly.
class QuoteChecksTimeoutJob < ApplicationJob
  queue_as :default

  def perform
    quote_checks = QuoteCheck.pending.order(started_at: :asc)
    return unless quote_checks.any?

    quote_checks.each { QuoteCheckTimeout.new(it).check }
  end
end
