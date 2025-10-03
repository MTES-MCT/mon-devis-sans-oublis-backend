# frozen_string_literal: true

# Tools to handle JSON OpenAPI schemas.
module JsonOpenapi
  def self.compact_schema(schema)
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

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.make_schema_refs_inline!(schema) # rubocop:disable Layout/MethodLength
    # Recursively replace $ref #/components/schemas/X objects with their corresponding X schemas
    replace_refs = lambda do |obj, components|
      case obj
      when Hash
        if obj.key?("$ref")
          ref_path = obj["$ref"].sub("#/components/schemas/", "")
          components[ref_path] || obj
        else
          obj.transform_values { |value| replace_refs.call(value, components) }
        end
      when Array
        obj.map { |item| replace_refs.call(item, components) }
      else
        obj
      end
    end

    if schema["components"] && schema["components"]["schemas"]
      components = schema["components"]["schemas"]
      schema.replace(replace_refs.call(schema, components))
    end

    schema
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
end
