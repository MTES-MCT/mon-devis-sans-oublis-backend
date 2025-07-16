# frozen_string_literal: true

require "swagger_helper"

describe "Data Checks API" do
  path "/data_checks/geste_types" do
    get "Récupérer les types de gestes disponibles" do
      tags "Checks"
      produces "application/json"

      response "200", "liste des types de gestes" do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   data: { type: "#/components/schemas/geste_type" }
                 }
               },
               required: ["data"]
        run_test!
      end
    end
  end

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

      # TODO: Fix indempotency of this test
      # response "404", "SIRET inexistant" do
      #   schema "$ref" => "#/components/schemas/data_check_result"

      #   let(:siret) { "12345678900000" } # wrong SIRET

      #   VCR.use_cassette("data_checks/siret_inexistant_404") do
      #     run_test!
      #   end
      # end
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
        parameter name: :geste_types, in: :query, # , type: :string,
                  type: :array, items: { type: :string },
                  style: :form, explode: false,
                  example: %w[menuiserie_fenetre_toit vmc_double_flux],
                  description: "Type(s) de gestes séparés par des virgules, retournent les certificats correspondants à l'un des gestes" # rubocop:disable Layout/LineLength

        schema "$ref" => "#/components/schemas/data_check_rge_result"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { "Q90513" } # valid RGE
        let(:date) { "2024-07-08" } # optional date
        let(:geste_types) { [] } # optional geste types

        run_test!
      end

      response "400", "RGE non valide" do
        schema "$ref" => "#/components/schemas/data_check_rge_result"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { "Q90514" } # invalid RGE
        let(:date) { "2023-10-01" } # optional date
        let(:geste_types) { [] } # optional geste types

        run_test!
      end

      response "400", "SIRET non valide" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "12345678900000" } # wrong SIRET
        let(:rge) { "Q90513" } # valid RGE
        let(:date) { "2023-10-01" } # optional date
        let(:geste_types) { [] } # optional geste types

        run_test!
      end

      response "400", "RGE non valide pour Date" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { "Q90513" } # valid RGE
        let(:date) { "1990-10-01" } # optional date
        let(:geste_types) { [] } # optional geste types

        run_test!
      end

      response "404", "RGE non trouvé pour Date" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { nil }
        let(:date) { "1990-10-01" } # optional date
        let(:geste_types) { [] } # optional geste types

        run_test!
      end

      response "422", "Geste type invalide" do
        schema "$ref" => "#/components/schemas/data_check_rge_result"

        let(:siret) { "52503410400014" } # valid SIRET
        let(:rge) { nil }
        let(:date) { nil }
        let(:geste_types) { ["abcd"] } # optional date

        run_test!
      end
    end
  end
end
