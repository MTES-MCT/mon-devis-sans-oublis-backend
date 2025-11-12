# frozen_string_literal: true

class AddEmailToToQuoteChecksAndQuotesCases < ActiveRecord::Migration[8.0]
  def change
    add_column :quote_checks, :email_to, :string
    add_index :quote_checks, :email_to
    add_column :quotes_cases, :email_to, :string
    add_index :quotes_cases, :email_to
  end
end
