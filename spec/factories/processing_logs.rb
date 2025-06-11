# frozen_string_literal: true

FactoryBot.define do
  factory :processing_logs do
    association :processable, factory: :quotes_check, strategy: :build

    started_at { Time.current }
    finished_at { nil }
  end
end
