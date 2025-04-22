# frozen_string_literal: true

require "swagger_helper"

describe "Devis API", swagger_doc: "v1/#{Rails.application.config.openapi_file.call('v1', 'internal')}" do
  path "/quote_checks/{id}" do
    patch "Mettre à jour un Devis" do
      tags "Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :string, required: true

      parameter name: :quote_check, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string }
        }
      }

      response "200", "Devis mis à jour" do
        schema "$ref" => "#/components/schemas/quote_check"

        let(:id) { create(:quote_check).id }
        let(:quote_check) { { comment: "test" } }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
