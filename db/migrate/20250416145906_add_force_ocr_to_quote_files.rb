# frozen_string_literal: true

class AddForceOcrToQuoteFiles < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_files, :force_ocr, :boolean, default: false, null: false
  end
end
