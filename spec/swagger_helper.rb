# frozen_string_literal: true

require "rails_helper"
require "uri"

ADEME_SWAGGER_URI = "https://data.ademe.fr/data-fair/api/v1/datasets/liste-des-entreprises-rge-2/api-docs.json"
ademe_yaml = URI.open(ADEME_SWAGGER_URI).read # rubocop:disable Security/Open
ademe_swagger = YAML.safe_load(ademe_yaml, aliases: true)
ademe_result_schema = ademe_swagger.dig("paths", "/lines", "get", "responses", "200", "content", "application/json",
                                        "schema", "properties", "results", "items", "properties")

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
        api_error: {
          type: :object,
          properties: {
            error: { type: :string },
            message: {
              type: :array,
              items: { type: :string }
            }
          }
        },
        profile: {
          type: :string,
          enum: QuoteCheck::PROFILES,
          description: "hérité du QuoteCase à la création si vide"
        },
        renovation_type: {
          type: :string,
          enum: QuoteCheck::RENOVATION_TYPES,
          description: "hérité du QuoteCase à la création si vide"
        },
        quote_check_metadata: {
          type: :object,
          properties: I18n.t("quote_checks.metadata").to_h do |key, values|
            enum = values.first.is_a?(Hash) ? values.flat_map { |it| it.fetch(:values) } : values

            [key, {
              type: :array,
              items: { type: :string, enum: }
            }]
          end,
          description: "hérité du QuoteCase à la création si vide"
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
        quote_check_error_type: {
          type: :string,
          enum: QuoteValidator::Global.error_types.keys,
          description: QuoteValidator::Global.error_types.map do |type, description|
            "#{type}: #{description}"
          end.join(" | ")
        },
        data_check_result: {
          type: :object,
          properties: {
            error_details: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  code: { "$ref" => "#/components/schemas/quote_check_error_code" }
                }
              },
              description: "liste des erreurs avec détails dans ordre à afficher",
              nullable: true
            },
            valid: { type: :boolean, nullable: true }
          }
        },
        quote_check_error_details: {
          type: :object,
          properties: {
            id: {
              type: :string,
              description: "UUID unique"
            },
            geste_id: { type: :string, nullable: true },
            category: { "$ref" => "#/components/schemas/quote_check_error_category" },
            type: { "$ref" => "#/components/schemas/quote_check_error_type" },
            code: { "$ref" => "#/components/schemas/quote_check_error_code" },
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
        },
        quote_check_geste: {
          type: :object,
          properties: {
            id: { type: :string },
            intitule: { type: :string },
            valid: { type: :boolean, nullable: true }
          },
          required: %w[id intitule]
        },
        quote_check_private_data_qa_attributes: {
          type: :object,
          nullable: true,
          properties: {
            pro: {
              type: :object,
              properties: {
                siret: {
                  type: :string,
                  nullable: true
                },
                adresse: {
                  type: :string,
                  nullable: true
                },
                capital: {
                  type: :string,
                  nullable: true
                },
                assurance: {
                  type: :string,
                  nullable: true
                },
                numero_tva: {
                  type: :string,
                  nullable: true
                },
                rge_labels: {
                  type: :array,
                  items: {
                    type: :string
                  }
                },
                raison_sociale: {
                  type: :string,
                  nullable: true
                },
                forme_juridique: {
                  type: :string,
                  nullable: true
                }
              }
            },

            noms: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            rnes: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            uris: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            ibans: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            emails: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            sirets: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            version: {
              type: :string
            },
            adresses: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            assurances: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            numero_rge: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            telephones: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            numero_rcss: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            numeros_tva: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            pro_adresses: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            capital_social: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            client_prenoms: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            client_adresses: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            client_civilite: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            raison_sociales: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            forme_juridiques: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            client_noms_de_famille: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            },
            ville_immatriculation_rcss: {
              type: :array,
              nullable: true,
              items: {
                type: :string
              }
            }

          }
        },
        quote_check_read_attributes_extended_data: {
          type: :object,
          nullable: true,
          properties: {
            from_sirets: {
              type: :array,
              items: { "$ref" => "#/components/schemas/ademe_result_schema" },
              nullable: true
            }
          }
        },
        quote_check_qa_attributes: {
          type: :object,
          nullable: true,
          properties: {
            version: {
              type: :string
            },
            mention_devis: {
              type: :boolean
            },
            numero_devis: {
              type: :string,
              nullable: true
            },
            pro_forme_juridique: {
              type: :string,
              nullable: true
            },
            date_devis: {
              type: :date,
              nullable: true
            },
            validite: {
              type: :boolean,
              nullable: true
            },
            date_debut_chantier: {
              type: :date,
              nullable: true
            },
            delai_debut_chantier: {
              type: :date,
              nullable: true
            },
            date_pre_visite: {
              type: :date,
              nullable: true
            },
            separation_prix_fourniture_pose: {
              type: :boolean,
              nullable: true,
              description: "Vérifiez qu'il y a une ligne distincte pour la pose, l'installation ou la main d'œuvre"
            },
            prix_total_ht: {
              type: :float,
              nullable: true
            },
            prix_total_ttc: {
              type: :float,
              nullable: true
            },
            tva: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  taux_tva: {
                    type: :float,
                    nullable: true
                  },
                  prix_ht_total: {
                    type: :float,
                    nullable: true
                  },
                  montant_tva_total: {
                    type: :float,
                    nullable: true
                  }
                }
              }
            }
          }
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
              description: "disponible si appelé depuis QuoteCase et non directement"
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
              description: "hérité du QuoteCase à la création si vide",
              nullable: true
            },
            renovation_type: {
              allOf: [
                { "$ref" => "#/components/schemas/renovation_type" }
              ],
              description: "hérité du QuoteCase à la création si vide",
              nullable: true
            },
            metadata: {
              allOf: [
                { "$ref" => "#/components/schemas/quote_check_metadata" }
              ],
              description: "hérité du QuoteCase à la création si vide",
              nullable: true
            },
            gestes: {
              type: :array,
              items: { "$ref" => "#/components/schemas/quote_check_geste" },
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
                  }
                }
              ]
            },
            qa_attributes: { "$ref" => "#/components/schemas/quote_check_qa_attributes" }
          },
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
            comment: {
              type: :string,
              nullable: true,
              description: "requis pour feedback error detail",
              maxLength: QuoteCheckFeedback.validators_on(:comment).detect do |validator|
                validator.is_a?(ActiveModel::Validations::LengthValidator)
              end&.options&.[](:maximum)
            }
          },
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
            metadata: { "$ref" => "#/components/schemas/quote_check_metadata", nullable: true }
          },
          required: %w[id]
        },
        stats: {
          type: :object,
          properties: {
            quote_checks_count: { type: :integer },
            average_quote_check_errors_count: {
              type: :float,
              description: "nombre moyen d'erreurs par analyse, arrondi au décimal supérieur",
              nullable: true
            },
            average_quote_check_cost: {
              type: :float,
              description: "coût moyen d'une analyse en Euro (€), arrondi au centime supérieur",
              nullable: true
            },
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
          required: %w[
            quote_checks_count
            average_quote_check_errors_count
            average_quote_check_cost
            unique_visitors_count
          ]
        }
      }
    },
    servers: [ # Swagger reccomends to have path version listed inside server URLs
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
      if ENV.key?("APPLICATION_HOST") # current host
        {
          url: "http#{Rails.env.development? ? '' : 's'}://#{Rails.application.config.application_host}",
          variables: {
            defaultHost: {
              default: Rails.application.config.application_host
            }
          }
        }
      end || nil,
      { # example host
        url: "http#{Rails.env.development? ? '' : 's'}://{defaultHost}",
        variables: {
          defaultHost: {
            default: Rails.application.config.application_host
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
