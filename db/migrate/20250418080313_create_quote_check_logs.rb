# frozen_string_literal: true

class CreateQuoteCheckLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :quote_check_logs, id: :uuid do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.uuid :quote_check_id, null: false, index: true
      t.datetime :started_at, null: false
      t.datetime :finished_at
    end
  end
end
