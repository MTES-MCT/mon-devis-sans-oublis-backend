# frozen_string_literal: true

# Tools to handle JSON OpenAPI schemas.
module JsonOpenapi
  def compact_schema(schema)
    case schema
    when Hash
      schema.except("description", "title", "examples", "x-enum-labels", "x-release-date", "x-appinfo", "info",
                    "minLength", "maxLength", "pattern")
            .transform_values { compact_schema(it) }
    when Array
      schema.map { compact_schema(it) }
    else
      schema
    end
  end

  def make_schema_refs_inline!(schema)
    # TODO: adapt to autodetect refs and replace them
    if (donnees_contextuelles = schema.dig("components", "schemas", "donnees_contextuelles"))
      donnees_contextuelles_parent_ref = schema.dig("components", "schemas", "rnt", "properties", "projet_travaux",
                                                    "properties")
      if donnees_contextuelles_parent_ref.key?("donnees_contextuelles")
        donnees_contextuelles_parent_ref["donnees_contextuelles"] =
          donnees_contextuelles
      end
    end

    schema
  end
end
