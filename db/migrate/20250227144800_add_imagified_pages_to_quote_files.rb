# frozen_string_literal: true

class AddImagifiedPagesToQuoteFiles < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_files, :imagified_pages, :text, array: true
  end
end
