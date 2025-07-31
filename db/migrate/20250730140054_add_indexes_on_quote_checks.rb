# frozen_string_literal: true

class AddIndexesOnQuoteChecks < ActiveRecord::Migration[8.0]
  def change
    add_index :quote_checks, :started_at
    add_index :quote_checks, :finished_at
    add_index :quote_checks, :profile

    # use left to avoid PG::ProgramLimitExceeded error
    add_index :quote_checks, "left(qa_result::text, 1)",
              where: "qa_result IS NOT NULL", name: "index_qa_result_not_null"
    add_index :quote_checks, "left(validation_errors::text, 1)",
              where: "validation_errors IS NOT NULL", name: "index_validation_errors_not_null"
  end
end
