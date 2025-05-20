# frozen_string_literal: true

# This class is responsible for managing the quote files in a same case.
class QuotesCase < ApplicationRecord
  include QuoteInputMetadata
  include QuotesCaseBackoffice
  include QuotesCasePostCheckMetadata

  has_many :quote_checks, inverse_of: :case, dependent: :destroy
end
