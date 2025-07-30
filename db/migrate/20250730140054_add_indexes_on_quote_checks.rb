# frozen_string_literal: true

class AddIndexesOnQuoteChecks < ActiveRecord::Migration[8.0]
  def change
    add_index :quote_checks, :started_at
    add_index :quote_checks, :finished_at
    add_index :quote_checks, :profile
    add_index :quote_checks, :qa_result
    add_index :quote_checks, :validation_errors
  end
end
