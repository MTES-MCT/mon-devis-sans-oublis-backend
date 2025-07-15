# frozen_string_literal: true

FactoryBot.define do
  factory :quote_check do
    source_name { "test" }

    profile { "artisan" }
    renovation_type { "geste" }

    file factory: %i[quote_file]

    started_at { Time.zone.now }

    trait :pending do
      finished_at { nil }
    end
    trait :finished do
      text do
        <<~TEXT
          Mon Devis contenu
          SIRET 12345678900000

          - Installation Chauffe-eau
        TEXT
      end
      anonymised_text do
        <<~TEXT
          Mon Devis contenu
          SIRET SIRETSIRETSIRE

          - Installation Chauffe-eau
        TEXT
      end

      naive_attributes { {} }
      naive_version { QuoteReader::NaiveText::VERSION }
      private_data_qa_attributes { {} }
      private_data_qa_result { {} }
      private_data_qa_version { QuoteReader::PrivateDataQa::VERSION }
      qa_attributes { build(:quote_check_qa_attributes) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
      qa_result { {} }
      qa_version { QuoteReader::Qa::VERSION }

      read_attributes { {} }

      finished_at { 5.minutes.from_now }

      validation_version { QuoteValidator::Global::VERSION }
      validation_errors { [] }
    end

    trait :valid do
      finished

      validation_version { QuoteValidator::Global::VERSION }
      validation_errors { [] }
    end
    trait :invalid do
      finished

      validation_version { QuoteValidator::Global::VERSION }
      validation_errors { validation_error_details&.map { it.fetch(:code) } || [] }
      validation_error_details do
        [{
          id: "1",
          code: "chauffage_etas_manquant",
          provided_value: "Installation Chauffe-eau"
        }]
      end
    end
  end
end
