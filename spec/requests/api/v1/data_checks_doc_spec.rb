# frozen_string_literal: true

require "swagger_helper"

describe "Data Checks API" do
  path "/data_checks/siret" do
    get "Vérifier le SIRET" do
      tags "Checks"
      produces "application/json"

      response "200", "SIRET existant" do
        parameter name: :siret, in: :query, type: :string, required: true

        schema type: :object,
               properties: {
                 siret: { type: :string, example: "12345678901234" },
                 valid: { type: :boolean, example: true }
               }

        let(:siret) { "13002526500013" } # Example of a valid SIRET

        run_test!
      end

      response "404", "SIRET inexistant" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "12345678900000" } # Example of a wrong SIRET

        run_test!
      end
    end
  end
end
