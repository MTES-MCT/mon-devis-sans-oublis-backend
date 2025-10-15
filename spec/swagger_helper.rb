# frozen_string_literal: true

# This file is used to configure the Swagger documentation generation
# via the Rswag gem. It contains the global metadata for the API documentation
# as well as the schema definitions used in the API.

# The results of the Swagger generation are stored in the `swagger` folder
# at the root of the Rails project.

require "rails_helper"
require "openssl"
require "uri"

ademe_result_schema = JSON.parse(Rails.root.join("swagger/v1/ademe_result_schema.json").read)

def date_type(options = {})
  options.merge(
    type: :string # because type: :date is not JSON Schema compliant
    # format: "date" # not supported by Mistral
  )
end

def float_type(options = {})
  options.merge(
    type: :number
    # might use multipleOf: 0.01
  )
end

# Via Rswag gems
RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s # TODO: doc

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  common_specs = {
    openapi: "3.0.1",
    info: {
      title: "#{Rails.application.config.application_name} API V1",
      version: "v1",
      description: <<~DESC
        [Vidéo explicative de l'API](https://mon-devis-sans-oublis.notion.site/API-Partenaire-Mon-Devis-Sans-Oublis-24268d71969180419721c8a272dffc6a)

        **Général champs:**
        - les champs optionnels sont nullables voir peuvent ne pas être présents dans le payload (corps de la requête)
        - `id` : considérer comme un string (chaîne de caractères) unique
        - type date string au format "YYYY-MM-DD" exemple "2025-05-27"
        - type datetime string au format ISO 8601 exemple "2025-05-27T14:53:00+02:00"
        - type enum (liste) : comme des strings (chaînes de caractères)
      DESC
    },
    paths: {},
    produces: ["application/json"],
    consumes: ["application/json"],
    components: {
      securitySchemes: {
        # basic_auth: {
        #   type: :http,
        #   scheme: :basic
        # },
        bearer_api_key: {
          type: :http,
          scheme: :bearer,
          bearerFormat: "API Key",
          description: "Renseignez votre clé API :"
        }
      },
      schemas: {
        ademe_result_schema: {
          type: :object,
          properties: ademe_result_schema
        },
        api_error_light: MdsoApiSchema.api_error_light,
        api_error: MdsoApiSchema.api_error_light(
          properties: {
            error_details: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_details" },
              description: "liste des erreurs avec détails dans ordre à afficher",
              nullable: true
            }
          }
        ),
        geste_type: {
          type: :string,
          enum: GesteTypes::VALUES
        },
        option: {
          type: :object,
          properties: {
            group: { type: :string, nullable: true, description: "groupe de l'option pour affichage" },
            label: { type: :string, description: "label de l'option à afficher" },
            value: { type: :string }
          },
          additionalProperties: false,
          description: "Option type enum"
        },
        profile: {
          type: :string,
          enum: QuoteCheck::PROFILES,
          description: "hérité du QuotesCase à la création si vide"
        },
        renovation_type: {
          type: :string,
          enum: QuoteCheck::RENOVATION_TYPES,
          description: "hérité du QuotesCase à la création si vide"
        },
        quote_check_metadata: {
          type: :object,
          properties: QuoteCheck.metadata_values.to_h do |key, values|
            enum = values.first.is_a?(Hash) ? values.flat_map { it.fetch(:values) } : values

            [key, {
              type: :array,
              items: { type: :string, enum: }
            }]
          end,
          additionalProperties: false,
          description: "hérité du QuotesCase à la création si vide"
        },
        quote_check_status: {
          type: :string,
          enum: QuoteCheck::STATUSES,
          description: {
            "pending" => "analyse encore en cours",
            "valid" => "tout est valide",
            "invalid" => "invalide : au moins une erreur"
          }.slice(*QuoteCheck::STATUSES).map { |status, description| "#{status}: #{description}" }.join(" | ")
        },
        quote_check_error_category: {
          type: :string,
          enum: QuoteValidator::Global.error_categories.keys,
          description: QuoteValidator::Global.error_categories.map do |category, description|
            "#{category}: #{description}"
          end.join(" | ")
        },
        quote_check_error_code: {
          type: :string,
          # enum: QuoteCheck::ERRORS, # TODO
          description: "code d'erreur de validation"
        },
        quote_check_error_deletion_reason_code: {
          type: :string,
          description: "code de raison de suppression d'erreur, remplaçant le message d'erreur"
        },
        quotes_case_error_deletion_reason_code: {
          type: :string,
          description: "code de raison de suppression d'erreur, remplaçant le message d'erreur"
        },
        quote_check_error_type: {
          type: :string,
          enum: QuoteValidator::Global.error_types.keys,
          description: QuoteValidator::Global.error_types.map do |type, description|
            "#{type}: #{description}"
          end.join(" | ")
        },
        data_check_result: MdsoApiSchema.data_check_result,
        data_check_rge_result: MdsoApiSchema.data_check_result({
                                                                 "$ref" => "#/components/schemas/ademe_result_schema"
                                                               }),
        quote_check_error_details_light: MdsoApiSchema.quote_check_error_details_light,
        quote_check_error_details: MdsoApiSchema.quote_check_error_details_light(
          properties: {
            id: { type: :string, description: "UUID unique" },
            geste_id: { type: :string, nullable: true },
            category: { "$ref" => "#/components/schemas/quote_check_error_category" },
            type: { "$ref" => "#/components/schemas/quote_check_error_type" },
            title: { type: :string },
            problem: { type: :string, description: "Réutilisez le title si vide" },
            solution: { type: :string, description: "peut-être vide" },
            provided_value: { type: :string, description: "peut-être vide, ou ligne du geste correspondant" },
            value: { type: :string, description: "DEPRECATED" },
            comment: {
              type: :string,
              nullable: true,
              description: "commentaire manuel (humain), vide ou null pour retirer",
              maxLength: QuoteCheck::MAX_COMMENT_LENGTH
            },
            deleted: { type: :boolean, nullable: true }
          },
          required: %w[id code]
        ),
        quote_check_geste: {
          type: :object,
          properties: MdsoApiSchema.geste_properties.merge(
            id: { type: :string, description: "UUID unique" },
            valid: { type: :boolean, nullable: true }
          ),
          additionalProperties: false,
          required: %w[id intitule]
        },
        quote_check_private_data_qa_attributes: MdsoApiSchema.quote_check_private_data_qa_attributes,
        quote_check_read_attributes_extended_data: {
          type: :object,
          nullable: true,
          properties: {
            from_sirets: {
              type: :array,
              items: { "$ref" => "#/components/schemas/ademe_result_schema" },
              nullable: true
            }
          },
          additionalProperties: false
        },
        quote_check_qa_attributes: {
          type: :object,
          nullable: true,
          properties: {
            bad_file: {
              type: :boolean,
              nullable: true,
              description: "DEPRECATED, le fichier n'est pas un devis valide, unique propriété présente si true"
            },
            rge_labels: {
              type: :array,
              items: { type: :string }
            },
            type_fichier: {
              type: :string,
              enum: MdsoApiSchema::TYPE_FICHIERS,
              nullable: true
            },
            version: {
              type: :string,
              nullable: true
            },
            mention_devis: {
              type: :boolean,
              nullable: true
            },
            numero_devis: {
              type: :string,
              nullable: true
            },
            pro_forme_juridique: {
              type: :string,
              nullable: true
            },
            date_devis: date_type(
              nullable: true
            ),
            validite: {
              type: :boolean,
              nullable: true
            },
            date_debut_chantier: date_type(
              nullable: true
            ),
            delai_debut_chantier: date_type(
              nullable: true
            ),
            date_pre_visite: date_type(
              nullable: true
            ),
            separation_prix_fourniture_pose: {
              type: :boolean,
              nullable: true,
              description: "Vérifiez qu'il y a une ligne distincte pour la pose, l'installation ou la main d'œuvre"
            },
            prix_total_ht: float_type(
              nullable: true
            ),
            prix_total_ttc: float_type(
              nullable: true
            ),
            tva: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  taux_tva: float_type(
                    nullable: true
                  ),
                  prix_ht_total: float_type(
                    nullable: true
                  ),
                  montant_tva_total: float_type(
                    nullable: true
                  )
                },
                additionalProperties: false
              }
            },
            gestes: {
              type: :array,
              items: {
                type: :object,
                properties: MdsoApiSchema.geste_properties,
                additionalProperties: false
              }
            }
          },
          additionalProperties: false
        },
        quote_check: {
          type: :object,
          properties: {
            id: {
              type: :string,
              description: "UUID unique"
            },
            parent_id: { type: :string, nullable: true },
            case_id: {
              type: :string,
              nullable: true,
              description: "disponible si appelé depuis QuotesCase et non directement"
            },
            status: { "$ref" => "#/components/schemas/quote_check_status" },
            filename: { type: :string, nullable: true },
            reference: {
              type: :string,
              nullable: true,
              description: "référence optionnelle, NON unique"
            },
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
            gestes: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_geste" },
              nullable: true
            },
            control_codes: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_code" },
              description: "liste des codes des points contrôlés",
              nullable: true
            },
            controls_count: {
              type: :integer,
              description: "nombre de points contrôlés",
              nullable: true
            },
            errors: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_code" },
              description: "liste des erreurs dans ordre à afficher",
              nullable: true
            },
            error_details: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_details" },
              description: "liste des erreurs avec détails dans ordre à afficher",
              nullable: true
            },
            error_messages: {
              type: :object,
              additionalProperties: {
                type: :string,
                description: "code d'erreur => message"
              },
              nullable: true
            },
            started_at: { type: :datetime },
            finished_at: {
              type: :datetime,
              nullable: true
            },
            comment: {
              type: :string,
              nullable: true,
              description: "commentaire manuel (humain), vide ou null pour retirer",
              maxLength: QuoteCheck::MAX_COMMENT_LENGTH
            },
            result_link: {
              type: :string,
              nullable: true,
              description: "lien vers le résultat frontend"
            },
            private_data_qa_attributes: { "$ref" => "#/components/schemas/quote_check_private_data_qa_attributes" },
            read_attributes: {
              allOf: [
                { "$ref" => "#/components/schemas/quote_check_private_data_qa_attributes" },
                { "$ref" => "#/components/schemas/quote_check_qa_attributes" },
                {
                  type: :object,
                  nullable: true,
                  properties: {
                    extended_data: { "$ref" => "#/components/schemas/quote_check_read_attributes_extended_data" }
                  },
                  additionalProperties: false
                }
              ]
            },
            qa_attributes: { "$ref" => "#/components/schemas/quote_check_qa_attributes" }
          },
          additionalProperties: false,
          required: %w[id status profile]
        },
        quote_check_feedback: {
          type: :object,
          properties: {
            id: {
              type: :string,
              description: "UUID unique"
            },
            quote_check_id: { type: :string, nullable: false },
            validation_error_details_id: {
              type: :string,
              nullable: true,
              description: "requis pour feedback error detail"
            },
            rating: { type: :integer, nullable: true, description: "requis pour feedback global hors error detail" },
            email: { type: :string, nullable: true, description: "pour feedback global hors error detail" },
            comment: {
              type: :string,
              nullable: true,
              description: "requis pour feedback error detail",
              maxLength: QuoteCheckFeedback.validators_on(:comment).detect do |validator|
                validator.is_a?(ActiveModel::Validations::LengthValidator)
              end&.options&.[](:maximum)
            }
          },
          additionalProperties: false,
          required: %w[quote_check_id]
        },
        quotes_case: {
          type: :object,
          properties: {
            id: {
              type: :string,
              description: "UUID unique"
            },
            reference: {
              type: :string,
              nullable: true,
              description: "référence optionnelle, NON unique"
            },
            status: { "$ref" => "#/components/schemas/quote_check_status" },
            profile: { "$ref" => "#/components/schemas/profile" },
            renovation_type: { "$ref" => "#/components/schemas/renovation_type" },
            metadata: { "$ref" => "#/components/schemas/quote_check_metadata", nullable: true },
            quote_checks: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check" },
              description: "liste des analyses de devis (QuoteChecks) dans ce dossier",
              nullable: true
            },
            control_codes: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_code" },
              description: "liste des codes des points contrôlés",
              nullable: true
            },
            controls_count: {
              type: :integer,
              description: "nombre de points contrôlés",
              nullable: true
            },
            errors: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_code" },
              description: "liste des erreurs dans ordre à afficher",
              nullable: true
            },
            error_details: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_error_details" },
              description: "liste des erreurs avec détails dans ordre à afficher",
              nullable: true
            },
            error_messages: {
              type: :object,
              additionalProperties: {
                type: :string,
                description: "code d'erreur => message"
              },
              nullable: true
            },
            started_at: {
              type: :datetime
            },
            finished_at: {
              type: :datetime,
              nullable: true
            }
          },
          additionalProperties: false,
          required: %w[id]
        },
        stats: {
          type: :object,
          properties: {
            quote_checks_count: { type: :integer },
            average_quote_check_errors_count: float_type(
              description: "nombre moyen d'erreurs par analyse, arrondi au décimal supérieur",
              nullable: true
            ),
            average_quote_check_cost: float_type(
              description: "coût moyen d'une analyse en Euro (€), arrondi au centime supérieur",
              nullable: true
            ),
            average_quote_check_processing_time: {
              type: :integer,
              description: "temps moyen de traitement d'une analyse en secondes, arrondi supérieur",
              nullable: true
            },
            median_quote_check_processing_time: {
              type: :integer,
              description: "temps médian de traitement d'une analyse en secondes, arrondi supérieur",
              nullable: true
            },
            unique_visitors_count: {
              type: :integer,
              description: "nombre de visiteurs uniques dans le temps", nullable: true
            }
          },
          additionalProperties: false,
          required: %w[
            quote_checks_count
            average_quote_check_errors_count
            average_quote_check_cost
            unique_visitors_count
          ]
        }
      }
    },
    # Swagger reccomends to have path version listed inside server URLs
    servers: [ # rubocop:disable Style/ItBlockParameter
      {
        url: "https://api.staging.mon-devis-sans-oublis.beta.gouv.fr/api/v1",
        description: "Staging test server : accessible depuis CORS localhost"
      },
      {
        url: "https://api.mon-devis-sans-oublis.beta.gouv.fr/api/v1",
        description: "Production server"
      },
      {
        url: "http://localhost:3000/api/v1",
        description: "Development server"
      },
      if ENV.key?("APPLICATION_HOST") && ENV["APPLICATION_HOST"].exclude?(".ngrok-free.app") # current host
        {
          url: "http#{'s' unless Rails.env.development?}://#{Rails.application.config.application_host}",
          variables: {
            defaultHost: {
              default: Rails.application.config.application_host
            }
          }
        }
      end || nil,
      { # example host
        url: "http#{'s' unless Rails.env.development?}://{defaultHost}",
        variables: {
          defaultHost: {
            default: (if Rails.application.config.application_host.exclude?(".ngrok-free.app")
                        Rails.application.config.application_host
                      else
                        "localhost:3000"
                      end)
          }
        }
      }
    ].compact.uniq do
      url = it.fetch(:url).gsub("{defaultHost}", it.dig(:variables, :defaultHost, :default) || "")
      UriExtended.host_with_port(url)
    end
    #  .sort_by do |server|
    #    UriExtended.host_with_port(server[:url]) == Rails.application.config.application_host ? 0 : 1
    #  rescue URI::InvalidURIError
    #    1
    #  end
  }

  config.openapi_specs = {
    # First takes all request doc as default
    "v1/#{Rails.application.config.openapi_file.call('v1', 'partner')}" => common_specs.deep_merge(
      info: {
        title: "#{Rails.application.config.application_name} Partner API V1"
      }
    ),
    "v1/#{Rails.application.config.openapi_file.call('v1', 'internal')}" => common_specs.deep_merge(
      info: {
        title: "#{Rails.application.config.application_name} Internal API V1"
      }
    )
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
  # TODO: config.swagger_format = :json

  # TODO: config.openapi_strict_schema_validation = true
end
