# frozen_string_literal: true

class CreateQuotesCases < ActiveRecord::Migration[7.2]
  def change
    create_table :quotes_cases, id: :uuid do |t|
      t.string :quote_checks, :source_name, default: "mdso", index: true
      t.string :reference
      t.timestamps
    end

    change_table :quote_checks do |t|
      t.references :case, null: true, foreign_key: { to_table: :quotes_cases }, type: :uuid
    end
  end
end
