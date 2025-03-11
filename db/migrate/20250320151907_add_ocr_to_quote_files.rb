# frozen_string_literal: true

class AddOcrToQuoteFiles < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_files, :ocr, :string
  end
end
