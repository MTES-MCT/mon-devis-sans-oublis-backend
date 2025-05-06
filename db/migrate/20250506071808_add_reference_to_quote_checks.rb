# frozen_string_literal: true

class AddReferenceToQuoteChecks < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_checks, :reference, :string
    add_index :quote_checks, :reference

    add_index :quotes_cases, :reference
  end
end
