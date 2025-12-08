# frozen_string_literal: true

class AddExpectedRntInputXmlToQuoteChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :quote_checks, :expected_rnt_input_xml, :text
  end
end
