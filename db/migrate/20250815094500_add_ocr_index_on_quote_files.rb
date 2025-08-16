# frozen_string_literal: true

class AddOcrIndexOnQuoteFiles < ActiveRecord::Migration[8.0]
  def change
    add_index :quote_files, :filename
    add_index :quote_files, :content_type

    # use left to avoid PG::ProgramLimitExceeded error
    add_index :quote_files, "left(ocr_result::text, 1)",
              where: "ocr_result IS NOT NULL", name: "index_ocr_result_not_null"
  end
end
