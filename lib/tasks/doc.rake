# frozen_string_literal: true

require "fileutils"

namespace :doc do # rubocop:disable Metrics/BlockLength
  desc "Generate full documentation"
  task full: :environment do
    Rake::Task["doc:rnt_prompts"].invoke
    Rake::Task["doc:swagger"].invoke
  end

  desc "Generate RNT prompts documentation"
  task rnt_prompts: :environment do
    require_relative "../../lib/rnt/rnt_schema"

    directory = Rails.root.join("lib/rnt/rnt_works_data_prompts")
    FileUtils.mkdir_p(directory)

    global_prompt = RntSchema.new.prompt_travaux
    Rails.root.join(directory, "global.txt").write(global_prompt)

    types_travaux = RntSchema.new.types_travaux
    types_travaux.each do |type, description|
      type_travaux_prompt = RntSchema.new.prompt_travaux(type, description)
      Rails.root.join(directory, "#{type}.txt").write(type_travaux_prompt)
    end
  end

  desc "Generate API documentation"
  task swagger: :environment do |_t, _args|
    # 1. Copy the ADEME schema and sub-schema
    ademe_swagger_json = URI(DataAdeme.rge_openapi_uri).open(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
    ademe_swagger = YAML.safe_load(ademe_swagger_json, aliases: true)
    Rails.root.join("swagger/v1/ademe-liste-des-entreprises-rge-2_api-docs.json")
         .write(JSON.pretty_generate(ademe_swagger))

    ademe_result_schema = # change without usefullness
      ademe_swagger.dig("paths", "/lines", "get", "responses", "200", "content", "application/json", # rubocop:disable Style/ItBlockParameter
                        "schema", "properties", "results", "items", "properties")
                   .transform_values! do
        it.except("x-cardinality")
      end
    Rails.root.join("swagger/v1/ademe_result_schema.json")
         .write(JSON.pretty_generate(ademe_result_schema))

    # 2. Generate the Swagger files from rswag specs
    Rake::Task["rswag:specs:swaggerize"].invoke(
      PATTERN: "spec/**/*_doc_spec.rb"
    )

    # 3. Save the sub-schemas
    Rails.root.join("swagger/v1/quote_check_private_data_qa_attributes.json")
         .write(JSON.pretty_generate(MdsoApiSchema.quote_check_private_data_qa_attributes))
  end
end
