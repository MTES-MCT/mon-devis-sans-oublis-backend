# frozen_string_literal: true

class AddValidationControlsCountToQuoteChecks < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_checks, :validation_controls_count, :integer
  end
end
