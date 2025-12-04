# frozen_string_literal: true

require "swagger_helper"

describe "Auth API" do
  path "/auth/check" do
    get "Récupérer l'utilisateur courant" do
      operationId :getCurrentUser
      tags "Authentification"
      security [bearer_api_key: []]
      produces "application/json"

      response "200", "utilisateur courant" do
        schema type: :object,
               properties: {
                 user: { type: :string }
               },
               required: ["user"]

        # See https://github.com/rswag/rswag/issues/316
        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:Authorization) { "wrongApiKey" } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
