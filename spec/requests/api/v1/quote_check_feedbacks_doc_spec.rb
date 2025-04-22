# frozen_string_literal: true

require "swagger_helper"

describe "Devis API", swagger_doc: "v1/#{Rails.application.config.openapi_file.call('v1', 'internal')}" do
  path "/quote_checks/{quote_check_id}/feedbacks" do
    # TODO: i18n?
    post "Déposer un retour global ou sur error detail" do
      tags "Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :quote_check_id, in: :path, type: :string
      parameter name: :quote_check_feedback, in: :body, schema: {
        oneOf: [
          {
            type: :object,
            properties: {
              rating: { type: :integer, nullable: false, description: "de 0 à 5 (trés satisfait) inclus", example: 2 },
              email: { type: :string, nullable: true, example: nil },
              comment: {
                type: :string,
                nullable: true,
                maxLength: QuoteCheckFeedback.validators_on(:comment).detect do |validator|
                  validator.is_a?(ActiveModel::Validations::LengthValidator)
                end&.options&.[](:maximum)
              }
            },
            required: %w[rating]
          },
          {
            type: :object,
            properties: {
              validation_error_details_id: { type: :string, nullable: false },
              comment: {
                type: :string,
                nullable: true,
                maxLength: QuoteCheckFeedback.validators_on(:comment).detect do |validator|
                  validator.is_a?(ActiveModel::Validations::LengthValidator)
                end&.options&.[](:maximum)
              }
            },
            required: %w[validation_error_details_id comment]
          }
        ]
      }

      let(:quote_check) { create(:quote_check, :invalid) }
      let(:quote_check_id) { quote_check.id }

      context "with global feedback" do
        let(:quote_check_feedback) do
          build(:quote_check_feedback, :global, quote_check: quote_check).attributes
        end

        response "201", "Retour téléversé" do
          schema "$ref" => "#/components/schemas/quote_check_feedback"

          # See https://github.com/rswag/rswag/issues/316
          let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

          run_test!
        end

        response "422", "missing params" do
          schema "$ref" => "#/components/schemas/api_error"

          let(:quote_check_feedback) { build(:quote_check_feedback, :global).attributes.merge("rating" => nil) }

          let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

          run_test!
        end
      end

      context "with error detail only feedback" do
        let(:quote_check_feedback) do
          build(:quote_check_feedback, :error_detail, quote_check: quote_check).attributes
        end

        response "201", "Retour téléversé" do
          schema "$ref" => "#/components/schemas/quote_check_feedback"

          # See https://github.com/rswag/rswag/issues/316
          let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

          run_test!
        end

        response "422", "missing params" do
          schema "$ref" => "#/components/schemas/api_error"

          let(:quote_check_feedback) do
            build(:quote_check_feedback, :error_detail).attributes.merge("comment" => nil)
          end

          let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

          run_test!
        end
      end
    end
  end
end
