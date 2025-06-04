class AddOcrResultToQuoteFiles < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_files, :ocr_result, :jsonb
    add_index :quote_files, :ocr
  end
end
