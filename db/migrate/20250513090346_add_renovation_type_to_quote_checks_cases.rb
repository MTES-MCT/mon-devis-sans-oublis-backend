# frozen_string_literal: true

class AddRenovationTypeToQuoteChecksCases < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_checks, :renovation_type, :string, null: false, default: "geste"
    add_index :quote_checks, :renovation_type
    add_column :quotes_cases, :renovation_type, :string, null: false, default: "ampleur"
    add_index :quotes_cases, :renovation_type
  end
end
