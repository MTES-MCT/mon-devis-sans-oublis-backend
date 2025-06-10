# frozen_string_literal: true

class CreateProcessingLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :processing_logs, id: :uuid do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :tags, array: true, default: []

      t.references :processable, polymorphic: true, type: :uuid, index: true
      t.jsonb :input_parameters
      t.jsonb :output_result

      t.datetime :started_at, null: false
      t.datetime :finished_at
    end
  end
end
