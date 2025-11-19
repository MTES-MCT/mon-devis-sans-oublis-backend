# frozen_string_literal: true

# Checks performed against the RNT (Référentiel National des Travaux).
class RntCheck < ApplicationRecord
  belongs_to :quote_check

  validates :sent_input_xml, presence: true
  validates :sent_at, presence: true

  def readonly?
    result_at_was || super
  end
end
