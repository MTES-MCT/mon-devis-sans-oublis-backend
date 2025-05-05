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
          reference: {
            type: :string,
            nullable: true
          }
        }
      }
      let(:quotes_case) { { reference: reference } }

      response "201", "Devis téléversé" do
        schema "$ref" => "#/components/schemas/quotes_case"

        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName
        let(:profile) { "test-ref" }

        run_test!
      end
    end
  end
end
