# frozen_string_literal: true

require "swagger_helper"

describe "Dossier API" do
  path "/quotes_cases" do
    # TODO: i18n?
    post "Créer un dossier de devis" do
      tags "Dossier"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quotes_case, in: :formData, schema: {
        type: :object,
        properties: {
          reference: { type: :string, nullable: true },
          profile: { "$ref" => "#/components/schemas/profile" },
          renovation_type: { "$ref" => "#/components/schemas/renovation_type" },
          metadata: { "$ref" => "#/components/schemas/quote_check_metadata", nullable: true }
        }
      }
      let(:quotes_case) do
        {
          reference: reference,
          profile: profile,
          renovation_type: renovation_type,
          metadata: metadata
        }
      end

      response "201", "Devis téléversé" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        schema "$ref" => "#/components/schemas/quotes_case"

        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        let(:reference) { "test-ref" }
        let(:profile) { "artisan" }
        let(:renovation_type) { "geste" }
        let(:metadata) { nil }

        run_test!
      end
    end
  end
end
