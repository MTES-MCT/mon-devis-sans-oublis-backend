# frozen_string_literal: true

class AddEmailSubjectToQuoteChecksAndQuotesCases < ActiveRecord::Migration[8.0]
  def change
    add_column :quote_checks, :email_subject, :string
    add_column :quotes_cases, :email_subject, :string
  end
end
