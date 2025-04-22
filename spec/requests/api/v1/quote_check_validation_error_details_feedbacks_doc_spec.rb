# frozen_string_literal: true

require "swagger_helper"

describe "Devis API", swagger_doc: "v1/#{Rails.application.config.openapi_file.call('v1', 'internal')}" do
  path "/quote_checks/{quote_check_id}/error_details/{error_details_id}/feedbacks" do
    # TODO: i18n?
    post "Déposer un retour" do
      tags "Erreurs Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quote_check_id, in: :path, type: :string
      parameter name: :error_details_id, in: :path, type: :string
      parameter name: :quote_check_feedback, in: :body, schema: {
        type: :object,
        properties: {
          comment: {
            type: :string,
            nullable: false,
            maxLength: QuoteCheckFeedback.validators_on(:comment).detect do |validator|
              validator.is_a?(ActiveModel::Validations::LengthValidator)
            end&.options&.[](:maximum)
          }
        },
        required: %w[comment]
      }

      let(:quote_check) { create(:quote_check, :invalid) }
      let(:quote_check_id) { quote_check.id }
      let(:error_details_id) { quote_check.validation_error_details.first.fetch("id") }
      let(:quote_check_feedback) do
        build(:quote_check_feedback, :error_detail, quote_check: quote_check).attributes
      end

      response "201", "Retour téléversé" do
        schema "$ref" => "#/components/schemas/quote_check_feedback"

        # See https://github.com/rswag/rswag/issues/316
        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "missing params" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:quote_check_feedback) do
          build(:quote_check_feedback).attributes
                                      .except("validation_error_details_id")
                                      .merge("comment" => nil)
        end

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
