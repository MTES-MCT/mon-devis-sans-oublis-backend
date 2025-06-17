# frozen_string_literal: true

class RemoveQuoteChecksStringOnQuotesCases < ActiveRecord::Migration[8.0]
  def change
    remove_column :quotes_cases, :quote_checks, :string, default: "mdso"
  end
end
