# frozen_string_literal: true

class AddEmailToQuoteChecksAndQuotesCases < ActiveRecord::Migration[8.0]
  def change
    add_column :quote_checks, :email, :string
    add_index :quote_checks, :email
    add_column :quotes_cases, :email, :string
    add_index :quotes_cases, :email
  end
end
