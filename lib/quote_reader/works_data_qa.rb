# frozen_string_literal: true

module QuoteReader
  # Read Quote text to extract Quote attributes by asking questions via LLM prompt online services
  class WorksDataQa < Text
    DEFAULT_LLM = ENV.fetch("WORKS_DATA_QA_DEFAULT_LLM", ENV.fetch("QA_DEFAULT_LLM", "mistral"))
    DEFAULT_MODEL = ENV.fetch("WORKS_DATA_QA_DEFAULT_MODEL", ENV.fetch("QA_DEFAULT_MODEL", "mistral-large-latest"))
    VERSION = "0.0.1"

    attr_reader :read_attributes, :result

    def self.json_schema
      path = Rails.root.join("swagger/v1/mon-devis-sans-oublis_api_v1_internal_swagger.yaml")
      yml = YAML.safe_load_file(path)
      yml.dig("components", "schemas").fetch("quote_check_qa_attributes")
    end

    def read(llm: nil)
      return {} if text.blank?

      llm_read_attributes(llm || DEFAULT_LLM)
    end

    private

    # According to prompts/works_data.txt, the attributes should be cleaned
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def clean_attributes(attributes) # rubocop:disable Metrics/MethodLength
      attributes&.merge(
        numero_devis: Array.wrap(
          attributes[:numero_devis] ||
          attributes[:devis_nos] ||
          attributes[:no_devis]
        ).presence&.map(&:to_s)&.first,
        devis_nos: nil, # cleaned up
        no_devis: nil, # cleaned up

        type_fichier: Array.wrap(attributes[:type_fichier]).presence&.map(&:to_s)&.first,

        gestes: attributes[:gestes]&.map do |geste|
          geste.merge(
            numero_ligne: geste[:numero_ligne]&.to_s,
            surface_isolant: Float(geste[:surface_isolant], exception: false)
          ).compact
        end
      )&.compact.presence
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def llm_read_attributes(llm) # rubocop:disable Metrics/MethodLength
      llm_klass = "Llms::#{llm.capitalize}".constantize
      return unless llm_klass.configured?

      processing_log = quote_file.start_processing_log("Qa", "Qa/#{llm_klass.name}") if quote_file

      llm = llm_klass.new(
        prompt,
        # json_schema: self.class.json_schema, # We lost quality and missed many data with schema enabled.
        result_format: :json
      )
      begin
        llm.chat_completion(text)
      rescue Llms::Base::TimeoutError, llm_klass::ResultError => e
        ErrorNotifier.notify(e)
        raise QuoteReader::LlmError, e
      end

      @read_attributes = clean_attributes(TrackingHash.new(llm.read_attributes))
      @result = llm.result

      quote_file.end_processing_log(processing_log) if processing_log

      read_attributes
    end
    # rubocop:enable Metrics/AbcSize

    def prompt
      Rails.root.join("lib/quote_reader/prompts/works_data.txt").read
    end
  end
end
