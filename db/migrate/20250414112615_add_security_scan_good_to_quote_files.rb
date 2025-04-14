# frozen_string_literal: true

class AddSecurityScanGoodToQuoteFiles < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_files, :security_scan_good, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
