# frozen_string_literal: true

# Makes QuoteFile easier for the Backoffice
module QuoteFileBackoffice
  extend ActiveSupport::Concern

  class_methods do
    def ransackable_attributes(_auth_object = nil)
      %w[
        filename
      ]
    end
  end
end
