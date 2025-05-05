# frozen_string_literal: true

FactoryBot.define do
  factory :quotes_case do
    profile { "test-ref" }
    source_name { "test" }
  end
end
