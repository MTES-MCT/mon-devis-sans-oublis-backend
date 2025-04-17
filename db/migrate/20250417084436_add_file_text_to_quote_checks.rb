# frozen_string_literal: true

class AddFileTextToQuoteChecks < ActiveRecord::Migration[7.2]
  def change
    change_table :quote_checks, bulk: true do |t|
      t.text :file_text
      t.text :file_markdown
    end
  end
end
