# frozen_string_literal: true

class AddProfileToQuoteCases < ActiveRecord::Migration[7.2]
  def change
    add_column :quotes_cases, :profile, :string, null: false, default: "conseiller"
  end
end
