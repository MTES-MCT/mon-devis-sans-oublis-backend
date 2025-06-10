# frozen_string_literal: true

class RemoveQuoteCheckLogs < ActiveRecord::Migration[8.0]
  def change
    drop_table :quote_check_logs do |t|
      t.references :quote_check, type: :uuid, index: true, foreign_key: { to_table: :quote_checks }

      t.datetime :started_at, null: false
      t.datetime :finished_at
    end
  end
end
