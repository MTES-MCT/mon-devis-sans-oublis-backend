# frozen_string_literal: true

require "swagger_helper"

describe "Dossier API", swagger_doc: "v1/#{Rails.application.config.openapi_file.call('v1', 'internal')}" do
  path "/quotes_cases/{id}/email_content" do
    get "Récupérer un Dossier et résultats de l'analyse au format HTML pour email" do
      tags "Dossier"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "text/html"
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "Dossier trouvé" do
        let(:id) { create(:quotes_case).id }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "404", "Dossier non trouvé" do
        let(:id) { SecureRandom.uuid }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    patch "Mettre à jour un Dossier" do
      tags "Dossier"
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
