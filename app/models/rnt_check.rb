# frozen_string_literal: true

# Checks performed against the RNT (Référentiel National des Travaux).
class RntCheck < ApplicationRecord
  belongs_to :quote_check

  validates :sent_input_xml, presence: true
  validates :sent_at, presence: true

  def readonly?
    result_at_was || super
  end

  def rnt_version
    Rnt::Schema.new.rnt_version(sent_input_xml)
  end

  def schema_version
    Rnt::Schema.new.schema_version(sent_input_xml)
  end
end
