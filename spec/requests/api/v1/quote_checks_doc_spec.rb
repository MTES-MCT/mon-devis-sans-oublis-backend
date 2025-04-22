# frozen_string_literal: true

require "swagger_helper"

describe "Devis API" do
  path "/quote_checks/metadata" do
    get "Récupérer les metadata possibles" do
      tags "Devis"
      produces "application/json"

      response "200", "liste des metadata possibles" do
        schema type: :object,
               properties: {
                 aides: {
                   type: :array,
                   data: { type: :string }
                 },
                 gestes: {
                   type: :array,
                   data: {
                     type: :object,
                     properties: {
                       group: { type: :string },
                       values: { type: :array, data: { type: :string } }
                     }
                   }
                 }
               },
               required: %w[aides gestes]
        run_test!
      end
    end
  end

  path "/quote_checks" do
    # TODO: i18n?
    post "Téléverser un devis" do
      tags "Devis"
      security [bearer_api_key: []]
      consumes "multipart/form-data"
      produces "application/json"

      parameter name: :quote_check, in: :formData, schema: {
        type: :object,
        properties: {
          file: {
            type: :string,
            format: :binary
          },
          file_text: {
            type: :string,
            description: "Texte brut du contenu du fichier",
            nullable: true
          },
          file_markdown: {
            type: :string,
            description: "Représentation Markdown du contenu du fichier",
            nullable: true
          },
          metadata: { "$ref" => "#/components/schemas/quote_check_metadata", nullable: true },
          profile: { "$ref" => "#/components/schemas/profile" },
          parent_id: { type: :string, nullable: true }
        },
        required: %w[file profile]
      }

      # See skip below
      # consumes 'application/x-www-form-urlencoded'

      # parameter name: :quote_check, in: :body, schema: {
      #   type: :object,
      #   properties: {
      #     file: {
      #       type: :string,
      #       format: :binary
      #     },
      #     profile: { "$ref" => "#/components/schemas/profile" }
      #   },
      #   required: %w[file profile]
      # }
      # parameter name: :file, in: :formData, schema: {
      #   type: :string,
      #   format: :binary
      # }, required: true
      # parameter name: :profile, in: :formData, schema: {
      #   "$ref" => "#/components/schemas/profile"
      # }, required: true

      let(:quote_check) { { file: file, profile: profile, metadata: metadata } }

      response "201", "Devis téléversé" do
        schema "$ref" => "#/components/schemas/quote_check"
        description "Au retour le devis a été téléversé avec succès.
Mais vérifiez selon le statut si le devis a été déjà analysé ou non.
Il peut contenir des erreurs dès le téléversement.
Si le statut est 'pending', cela signifie que l'analyse est encore en cours.
Et qu'il faut boucler sur l'appel /quote_check/:id pour récupérer le devis à jour.".gsub("\n", "<br>")

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        # See https://github.com/rswag/rswag/issues/316
        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName
        let(:profile) { "artisan" }
        let(:metadata) { nil }

        pending "fix why quote_check params are not sent"
        # run_test!
      end

      response "422", "missing params" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        let(:profile) { nil }
        let(:metadata) { nil }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        let(:profile) { "blabla" }
        let(:metadata) { nil }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "invalid request for metadata" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        let(:profile) { "artisan" }
        let(:metadata) { { toto: "tata " } }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
