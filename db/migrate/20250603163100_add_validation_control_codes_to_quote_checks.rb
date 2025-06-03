# frozen_string_literal: true

class AddValidationControlCodesToQuoteChecks < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_checks, :validation_control_codes, :jsonb
  end
end
