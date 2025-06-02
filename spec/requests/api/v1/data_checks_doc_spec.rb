# frozen_string_literal: true

require "swagger_helper"

describe "Data Checks API" do
  path "/data_checks/siret" do
    get "Vérifier le SIRET" do
      tags "Checks"
      produces "application/json"

      response "200", "SIRET existant" do
        parameter name: :siret, in: :query, type: :string, required: true

        schema "$ref" => "#/components/schemas/data_check_result"

        let(:siret) { "13002526500013" } # valid SIRET

        run_test!
      end

      response "404", "SIRET inexistant" do
        schema "$ref" => "#/components/schemas/data_check_result"

        let(:siret) { "12345678900000" } # wrong SIRET

        run_test!
      end
    end
  end

  path "/data_checks/rge" do
    get "Trouver ou Valider un RGE, selon SIRET et/ou critères" do
      tags "Checks"
      produces "application/json"

      response "200", "RGE trouvé ou vérifié" do
        parameter name: :siret, in: :query, type: :string,
                  description: "SIRET", required: true
        parameter name: :rge, in: :query, type: :string,
                  description: "RGE à Valider, sinon Trouve un RGE selon les critères"
        parameter name: :date, in: :query, type: :date

        schema "$ref" => "#/components/schemas/data_check_result"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { "Q90513" } # valid RGE
        let(:date) { "2024-07-08" } # optional date

        run_test!
      end

      response "400", "RGE non valide" do
        schema "$ref" => "#/components/schemas/data_check_result"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { "Q90514" } # invalid RGE
        let(:date) { "2023-10-01" } # optional date

        run_test!
      end

      response "400", "SIRET non valide" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "12345678900000" } # wrong SIRET
        let(:rge) { "Q90513" } # valid RGE
        let(:date) { "2023-10-01" } # optional date

        run_test!
      end

      response "400", "RGE non valide pour Date" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { "Q90513" } # valid RGE
        let(:date) { "1990-10-01" } # optional date

        run_test!
      end

      response "404", "RGE non trouvé pour Date" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { nil }
        let(:date) { "1990-10-01" } # optional date

        run_test!
      end
    end
  end
end
