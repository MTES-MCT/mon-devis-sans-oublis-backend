# frozen_string_literal: true

FactoryBot.define do
  factory :quotes_case do
    source_name { "test" }

    profile { "conseiller" }
    renovation_type { "ampleur" }

    trait :invalid do
      after(:build) do |quotes_case|
        quotes_case.validation_error_details = [
          {
            "id" => "#{quotes_case.id}-1",
            "code" => "client_nom_incoherent",
            "details" => { "category" => "case_incoherence", "type" => "error" }
          }
        ]
      end

      after(:create) do |quotes_case|
        create_list(:quote_check, 2, :invalid, case: quotes_case)
      end
    end
  end
end
