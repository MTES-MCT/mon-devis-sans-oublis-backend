# frozen_string_literal: true

class AddMetadataToQuotesCases < ActiveRecord::Migration[7.2]
  def change
    add_column :quotes_cases, :metadata, :jsonb
  end
end
