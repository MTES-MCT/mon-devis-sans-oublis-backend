# frozen_string_literal: true

module Llms
  # Base API client
  class Base # rubocop:disable Metrics/ClassLength
    class ResultError < StandardError; end
    class TimeoutError < ResultError; end

    attr_reader :json_schema, :model, :prompt, :result_format

    RESULT_FORMATS = %i[numbered_list json xml].freeze

    def initialize(prompt, json_schema: nil, model: nil, result_format: :json)
      @prompt = prompt

      raise NotImplementedError, "JSON Schema with $ref are not supported" if json_schema&.to_json&.include?("$ref")

      @json_schema = JsonOpenapi.make_schema_refs_inline!(json_schema) if json_schema
      @model = model

      raise ArgumentError, "Invalid result format: #{result_format}" unless RESULT_FORMATS.include?(result_format)

      @result_format = result_format
    end

    def compacted_schema
      JsonOpenapi.compact_schema(json_schema)
    end

    def self.clean_value(text)
      # rubocop:disable Style/SafeNavigationChainLength
      text&.strip
          &.gsub(/^[\W\s]+$/i, "")
          &.gsub(/^\**\s*/i, "")
          &.gsub(/^Aucune?s?(?:\s+.+\s+)?(?: *mention(?:née?)?s?)?\.?(?:\s*.+)?$/i, "")
          &.gsub(/\(?(?:Non (?:disponibles?|mention(?:née?)?s?|spécifiée?s?)\.?|Aucune?s? .+ n'est mentionnée?s?\.?|Inconnue?s? \(pas de [^)]+\))\)?\.?/i, "") # rubocop:disable Layout/LineLength
          &.presence
      # rubocop:enable Style/SafeNavigationChainLength
    end

    def self.configured?
      raise NotImplementedError
    end

    def self.extract_json(text)
      (
        text[/```json.?+(\{.+\})/im, 1] || text[/(\{.+\})/im, 1]
      )&.gsub(/"version": ([\d.]+)/, '"version": "\1"') # TODO: Remove version temporary fix
    end

    def self.extract_jsx(text)
      return unless text&.match?(/```jsx\n/i)

      text[/(\{.+\})/im, 1]&.gsub(/(\w+):/, '"\1":')
    end

    def self.extract_markdown(text)
      text[/```markdown(.+)```/im, 1]&.strip if text&.match?(/```markdown\n/i)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.extract_numbered_list(text) # rubocop:disable Metrics/MethodLength
      parts = text.split(/^\n(?:\*\*\s*)?\d+\.\s+/)[1..]
      parts.each_with_index.map do |part, index|
        match = part.match(/^(?:\*\*\s*)?(?:\d+\.)?(?<label>.*?)(?:\s+\*\*)?\s*: *(?<value>\n*(?:\s*-\s*)?.*)$/m)
        raise ResultError, "Parsing numbered list inside match: #{match.to_a}" unless match

        next if match[:label]&.gsub("**", "").blank?

        is_address_search = match[:label].include?("dresse")
        detected_separator = [
          /\n+\s*-\s*/m,
          %r{/},
          is_address_search ? nil : /,/,
          /\n/,
          /\*\*:\s/
        ].compact.detect { match[:value].match?(it) }
        next if index.zero? && !detected_separator

        unless detected_separator
          raise ResultError,
                "Parsing numbered list without separator inside match: #{match.to_a}"
        end

        {
          number: Integer(index + 1),
          label: match[:label]&.gsub("**", "")&.downcase&.strip.presence, # rubocop:disable Style/SafeNavigationChainLength
          value: match[:value]&.split(/\s*#{detected_separator}\s*/)&.filter_map { clean_value(it&.strip) }
        }
      end.compact.sort_by { it.fetch(:number) } # rubocop:disable Style/MultilineBlockChain
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def self.extract_xml(text)
      return text[/```xml(.+)```/im, 1]&.strip if text&.match?(/```xml\n/i)

      text[%r{<\?xml.+</.+>}im, 0]&.strip
    end

    def self.include_null_bytes?(text)
      text&.gsub("\x00", "")
    end

    def self.llm_from_result(result)
      return unless result

      case result["id"]
      when /\Achatcmpl-/
        "Albert"
      else
        "Mistral" if model_from_result(result)&.start_with?("mistral-")
      end
    end

    def self.model_from_result(result)
      result&.dig("model")
    end

    def self.remove_null_bytes(text)
      text&.gsub("\x00", "")
    end

    def self.sort_models(models)
      models.sort_by do |model|
        # Extract the size (e.g., "8B", "70B") and convert to an integer
        size = model.match(/-(\d+)B-/i)&.to_a&.last.to_i

        # Prioritize meta-llama models (-1 for meta-llama, 0 for others)
        priority = model.match?(/meta-llama/i) ? -1 : 0

        # Sort by priority first, then by size in descending order (negative size)
        [priority, -size]
      end
    end

    def chat_completion(text)
      raise NotImplementedError
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def extract_result(content, ignore_null_bytes: false) # rubocop:disable Metrics/MethodLength
      case result_format
      when :numbered_list
        @read_attributes = TrackingHash.nilify_empty_values(
          self.class.extract_numbered_list(content).to_h { [it.fetch(:label), it.fetch(:value)] }
        )
      when :xml
        self.class.extract_xml(content)
      else # :json
        json = content.deep_symbolize_keys if content.is_a?(Hash)

        unless json
          content_jsx_result = self.class.extract_jsx(content)
          unless content_jsx_result
            content_json_result = self.class.extract_json(content)
            raise ResultError, "JSON content empty: #{content}" unless content_json_result
          end

          try_null_bytes = false
          json_result = content_json_result || content_jsx_result
          begin
            json = JSON.parse(json_result, symbolize_names: true)
          rescue JSON::ParserError => e
            try_null_bytes = e.message.include?("invalid ASCII") && !ignore_null_bytes
            raise ResultError, "Parsing JSON inside content: #{json_result}" unless try_null_bytes
          end
          return extract_result(self.class.remove_null_bytes(content), ignore_null_bytes: true) if try_null_bytes
        end

        @read_attributes = TrackingHash.nilify_empty_values(json)
        raise ResultError, "No attributes for JSON: #{json_result}" if @read_attributes.empty?

        @read_attributes
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize
  end
end
