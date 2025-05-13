# frozen_string_literal: true

# Makes QuotesCase easier for the Backoffice
module QuotesCaseBackoffice
  extend ActiveSupport::Concern

  class_methods do
    def ransackable_associations(_auth_object = nil)
      []
    end

    def ransackable_attributes(_auth_object = nil)
      %w[
        created_at

        source_name
        reference
        profile
        renovation_type
      ]
    end
  end
end
