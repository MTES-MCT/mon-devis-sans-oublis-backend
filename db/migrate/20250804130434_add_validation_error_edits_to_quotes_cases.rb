# frozen_string_literal: true

class AddValidationErrorEditsToQuotesCases < ActiveRecord::Migration[8.0]
  def change
    change_table :quotes_cases, bulk: true do |t|
      t.jsonb :validation_error_edits
      t.datetime :validation_error_edited_at
    end
  end
end
