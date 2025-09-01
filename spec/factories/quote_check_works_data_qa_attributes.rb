# frozen_string_literal: true

# Following the prompt and related Swagger Schema
FactoryBot.define do
  factory :quote_check_works_data_qa_attributes, class: Hash do
    skip_create
    initialize_with do
      {
        type_fichier: "devis"
      }.merge(attributes)
    end
  end
end
