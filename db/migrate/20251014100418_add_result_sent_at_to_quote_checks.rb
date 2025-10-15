# frozen_string_literal: true

class AddResultSentAtToQuoteChecks < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_checks, :result_sent_at, :datetime
    add_index :quote_checks, :result_sent_at
  end
end
