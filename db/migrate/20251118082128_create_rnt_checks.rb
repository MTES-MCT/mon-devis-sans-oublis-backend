# frozen_string_literal: true

class CreateRntChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :rnt_checks, id: :uuid do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :quote_check, type: :uuid, foreign_key: true

      t.text :sent_input_xml
      t.datetime :sent_at

      t.json :result_json
      t.datetime :result_at
    end

    add_index :rnt_checks, :sent_at
  end
end
