# frozen_string_literal: true

require "swagger_helper"

describe "Dossier API" do
  path "/quotes_cases" do
    # TODO: i18n?
    post "Créer un dossier de devis" do
      operationId :createQuotesCase
      tags "Dossiers"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quotes_case, in: :formData, schema: {
        type: :object,
        properties: {
          reference: { type: :string, nullable: true },
          profile: { "$ref" => "#/components/schemas/api_profile" },
          renovation_type: { "$ref" => "#/components/schemas/renovation_type" },
          metadata: {
            allOf: [
              { "$ref" => "#/components/schemas/quote_check_metadata" }
            ],
            nullable: true
          }
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

  path "/quotes_cases/{id}" do
    get "Récupérer un Dossier et résultats de l'analyse" do
      operationId :getQuotesCase
      tags "Dossiers"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "Dossier trouvé" do
        schema "$ref" => "#/components/schemas/quotes_case"

        let(:id) { create(:quotes_case).id }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "404", "Dossier non trouvé" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:id) { SecureRandom.uuid }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    patch "Mettre à jour un Dossier" do
      operationId :updateQuotesCase
      tags "Dossiers"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :string, required: true

      parameter name: :quotes_case, in: :body, schema: {
        type: :object,
        properties: {
          reference: { type: :string, nullable: true }
        }
      }

      response "200", "Devis mis à jour" do
        schema "$ref" => "#/components/schemas/quotes_case"

        let(:id) { create(:quotes_case).id }
        let(:quotes_case) { { reference: "test" } }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
