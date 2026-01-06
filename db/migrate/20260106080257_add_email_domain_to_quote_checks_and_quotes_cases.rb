# frozen_string_literal: true

class AddEmailDomainToQuoteChecksAndQuotesCases < ActiveRecord::Migration[8.1]
  def change
    add_column :quote_checks, :email_domain, :string
    add_index :quote_checks, :email_domain
    add_column :quotes_cases, :email_domain, :string
    add_index :quotes_cases, :email_domain
  end
end
