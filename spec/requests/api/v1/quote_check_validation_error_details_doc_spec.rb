# frozen_string_literal: true

require "swagger_helper"

describe "Error Details edition API" do
  path "/quote_checks/error_detail_deletion_reasons" do
    get "Récupérer les profils disponibles" do
      tags "Erreurs Devis"
      produces "application/json"

      response "200", "liste des raisons de suppression d'erreur" do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   additionalProperties: { "$ref" => "#/components/schemas/quote_check_error_deletion_reason_code" }
                 }
               },
               required: ["data"]
        run_test!
      end
    end
  end

  path "/quote_checks/{quote_check_id}/error_details/{error_details_id}" do
    post "Annuler la suppression d'un détail d'erreur donc le Ré-ajouter comme originellement" do
      tags "Erreurs Devis"
      security [basic_auth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quote_check_id, in: :path, type: :string, required: true
      parameter name: :error_details_id, in: :path, type: :string, required: true

      let(:quote_check) { create(:quote_check, :invalid) }
      let(:quote_check_id) { quote_check.id }
      let(:error_details_id) { quote_check.validation_error_details.first.fetch("id") }

      response "201", "détail d'erreur ré-ajouté" do
        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    delete "Supprimer un détail d'erreur" do
      tags "Erreurs Devis"
      security [basic_auth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quote_check_id, in: :path, type: :string, required: true
      parameter name: :error_details_id, in: :path, type: :string, required: true

      parameter name: :reason, in: :query, schema: {
                                             oneOf: [
                                               { "$ref" => "#/components/schemas/quote_check_error_deletion_reason_code" }, # rubocop:disable Layout/LineLength
                                               { type: :string,
                                                 maxLength: QuoteCheck::MAX_EDITION_REASON_LENGTH }
                                             ]
                                           },
                description: "Raison de la suppression (soit un code quote_check_error_deletion_reason_code ou champs libre)", # rubocop:disable Layout/LineLength
                maxLength: QuoteCheck::MAX_EDITION_REASON_LENGTH

      let(:quote_check) { create(:quote_check, :invalid) }
      let(:quote_check_id) { quote_check.id }
      let(:error_details_id) { quote_check.validation_error_details.first.fetch("id") }
      let(:reason) { "doublon" }

      response "204", "détail d'erreur supprimé" do
        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    patch "Modifier le commentaire sur le détail d'erreur" do
      tags "Erreurs Devis"
      security [basic_auth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quote_check_id, in: :path, type: :string, required: true
      parameter name: :error_details_id, in: :path, type: :string, required: true

      parameter name: :error_details, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string }
        }
      }

      let(:quote_check) { create(:quote_check, :invalid) }
      let(:quote_check_id) { quote_check.id }
      let(:error_details_id) { quote_check.validation_error_details.first.fetch("id") }
      let(:error_details) { { comment: "test" } }

      response "200", "détail d'erreur mis à jour" do
        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
