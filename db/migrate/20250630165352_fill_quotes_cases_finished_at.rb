# frozen_string_literal: true

class FillQuotesCasesFinishedAt < ActiveRecord::Migration[8.0]
  def change
    QuotesCase.where(finished_at: nil).find_each do |quotes_case|
      # Set finished_at to the maximum finished_at of its quote_checks
      max_finished_at = quotes_case.quote_checks.maximum(:finished_at)
      next unless max_finished_at

      updated_quotes_case = QuotesCaseCheckService.new(quotes_case, save: false).check
      updated_quotes_case.finished_at = max_finished_at
      updated_quotes_case.save!
    end
  end
end
