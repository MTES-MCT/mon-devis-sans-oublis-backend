# frozen_string_literal: true

require "swagger_helper"

describe "Error Details edition API",
         swagger_doc: "v1/#{Rails.application.config.openapi_file.call('v1', 'internal')}" do
  path "/quotes_cases/error_detail_deletion_reasons" do
    get "Récupérer les détails de suppression d'erreur disponibles" do
      tags "Erreurs Devis"
      produces "application/json"

      response "200", "liste des raisons de suppression d'erreur" do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   additionalProperties: { "$ref" => "#/components/schemas/quotes_case_error_deletion_reason_code" }
                 }
               },
               required: ["data"]
        run_test!
      end
    end
  end

  path "/quotes_cases/{quotes_case_id}/error_details/{error_details_id}" do
    post "Annuler la suppression d'un détail d'erreur donc le Ré-ajouter comme originellement" do
      tags "Erreurs Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quotes_case_id, in: :path, type: :string, required: true
      parameter name: :error_details_id, in: :path, type: :string, required: true

      let(:quotes_case) { create(:quotes_case, :invalid) }
      let(:quotes_case_id) { quotes_case.id }
      let(:error_details_id) { quotes_case.validation_error_details.first.fetch("id") }

      response "201", "détail d'erreur ré-ajouté" do
        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    delete "Supprimer un détail d'erreur" do
      tags "Erreurs Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quotes_case_id, in: :path, type: :string, required: true
      parameter name: :error_details_id, in: :path, type: :string, required: true

      parameter name: :reason, in: :query, schema: {
                                             oneOf: [
                                               { "$ref" => "#/components/schemas/quotes_case_error_deletion_reason_code" }, # rubocop:disable Layout/LineLength
                                               { type: :string,
                                                 maxLength: QuotesCase::MAX_EDITION_REASON_LENGTH }
                                             ]
                                           },
                description: "Raison de la suppression (soit un code quotes_case_error_deletion_reason_code ou champs libre)", # rubocop:disable Layout/LineLength
                maxLength: QuotesCase::MAX_EDITION_REASON_LENGTH
      let(:quotes_case) { create(:quotes_case, :invalid) }
      let(:quotes_case_id) { quotes_case.id }
      let(:error_details_id) { quotes_case.validation_error_details.first.fetch("id") }
      let(:reason) { "doublon" }

      response "204", "détail d'erreur supprimé" do
        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    patch "Modifier le commentaire sur le détail d'erreur" do
      tags "Erreurs Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quotes_case_id, in: :path, type: :string, required: true
      parameter name: :error_details_id, in: :path, type: :string, required: true

      parameter name: :error_details, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string }
        }
      }

      let(:quotes_case) { create(:quotes_case, :invalid) }
      let(:quotes_case_id) { quotes_case.id }
      let(:error_details_id) { quotes_case.validation_error_details.first.fetch("id") }
      let(:error_details) { { comment: "test" } }

      response "200", "détail d'erreur mis à jour" do
        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
