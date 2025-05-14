# frozen_string_literal: true

FactoryBot.define do
  factory :quotes_case do
    source_name { "test" }

    profile { "conseiller" }
    renovation_type { "ampleur" }
  end
end
