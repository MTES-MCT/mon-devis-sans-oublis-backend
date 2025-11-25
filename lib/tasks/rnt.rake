# frozen_string_literal: true

namespace :rnt do
  desc "Check QuoteChecks against the RNT (Référentiel National des Travaux)"
  task check_quotes: :environment do |_t, _args|
    QuoteCheck.where.missing(:rnt_checks).order(created_at: :desc).find_each do |quote_check|
      QuoteCheckRntValidateJob.perform_later(quote_check.id)
    end
  end
end
