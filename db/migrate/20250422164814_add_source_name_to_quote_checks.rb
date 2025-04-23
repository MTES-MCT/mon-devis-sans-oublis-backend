# frozen_string_literal: true

class AddSourceNameToQuoteChecks < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_checks, :source_name, :string, default: "mdso"
    add_index :quote_checks, :source_name
  end
end
