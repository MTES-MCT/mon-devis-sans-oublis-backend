# frozen_string_literal: true

class AddErrorsToQuotesCases < ActiveRecord::Migration[8.0]
  def change
    change_table :quotes_cases, bulk: true do |t|
      t.jsonb :validation_errors
      t.jsonb :validation_error_details
      t.string :validation_version
      t.integer :validation_controls_count
      t.jsonb :validation_control_codes

      t.datetime :finished_at
    end
  end
end
