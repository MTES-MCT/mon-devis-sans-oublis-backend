# frozen_string_literal: true

# This class is responsible for managing the quote files in a same case.
class QuotesCase < ApplicationRecord
  include QuotesCaseBackoffice

  has_many :quote_checks, inverse_of: :case, dependent: :destroy

  validates :source_name, presence: true

  scope :accessible_for_source, lambda { |source_name|
    where(source_name: source_name&.downcase) unless source_name&.downcase == "mdso"
  }

  before_validation do
    self.reference = reference.presence if reference
  end
end
