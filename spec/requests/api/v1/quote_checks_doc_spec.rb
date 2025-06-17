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
          reference: { type: :string, nullable: true },
          profile: {
            allOf: [
              { "$ref" => "#/components/schemas/profile" }
            ],
            description: "hérité du QuotesCase à la création si vide",
            nullable: true
          },
          renovation_type: {
            allOf: [
              { "$ref" => "#/components/schemas/renovation_type" }
            ],
            description: "hérité du QuotesCase à la création si vide",
            nullable: true
          },
          metadata: {
            allOf: [
              { "$ref" => "#/components/schemas/quote_check_metadata" }
            ],
            description: "hérité du QuotesCase à la création si vide",
            nullable: true
          },
          parent_id: {
            type: :string,
            description: "Ancienne soumission du fichier",
            nullable: true
          },
          case_id: {
            type: :string,
            description: "Dossier de devis pour rénovation d’ampleur",
            nullable: true
          }
        },
        required: %w[file]
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

      let(:quote_check) do
        {
          file: file,
          reference: reference,
          profile: profile,
          renovation_type: renovation_type,
          metadata: metadata
        }
      end

      response "201", "Devis téléversé" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        schema "$ref" => "#/components/schemas/quote_check"
        description "Au retour le devis a été téléversé avec succès.
Mais vérifiez selon le statut si le devis a été déjà analysé ou non.
Il peut contenir des erreurs dès le téléversement.
Si le statut est 'pending', cela signifie que l'analyse est encore en cours.
Et qu'il faut boucler sur l'appel /quote_check/:id pour récupérer le devis à jour.".gsub("\n", "<br>")

        # See https://github.com/rswag/rswag/issues/316
        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }

        let(:reference) { "test-ref" }
        let(:profile) { "artisan" }
        let(:renovation_type) { "geste" }
        let(:metadata) { nil }

        pending "fix why quote_check params are not sent"
        # run_test!
      end

      response "422", "missing params" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        schema "$ref" => "#/components/schemas/api_error"

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        let(:reference) { nil }
        let(:profile) { nil }
        let(:renovation_type) { nil }
        let(:metadata) { nil }

        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "invalid request" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        schema "$ref" => "#/components/schemas/api_error"

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        let(:reference) { nil }
        let(:profile) { "blabla" }
        let(:renovation_type) { "geste" }
        let(:metadata) { nil }

        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "invalid request for metadata" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        schema "$ref" => "#/components/schemas/api_error"

        let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
        let(:reference) { nil }
        let(:profile) { "artisan" }
        let(:renovation_type) { "geste" }
        let(:metadata) { { toto: "tata " } }

        let(:Authorization) { api_key_mdso_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end

  path "/quote_checks/{id}" do
    get "Récupérer un Devis" do
      tags "Devis"
      security [bearer_api_key: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "Devis trouvé" do
        schema "$ref" => "#/components/schemas/quote_check"

        let(:id) { create(:quote_check).id }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "404", "Devis non trouvé" do
        schema "$ref" => "#/components/schemas/api_error"

        let(:id) { SecureRandom.uuid }

        let(:Authorization) { api_key_header.fetch("Authorization") } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
