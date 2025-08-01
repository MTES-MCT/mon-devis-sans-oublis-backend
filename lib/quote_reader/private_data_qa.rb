# frozen_string_literal: true

module QuoteReader
  # Read Quote text to extract Private data attributes by asking questions via LLM prompt online services
  class PrivateDataQa < Text
    DEFAULT_LLM = ENV.fetch("PRIVATE_DATA_QA_DEFAULT_LLM", "albert")
    VERSION = "0.0.1"

    attr_reader :read_attributes, :result

    def read(llm: nil)
      return {} if text.blank?

      llm_read_attributes(llm || DEFAULT_LLM)
    end

    private

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def clean_attributes(attributes) # rubocop:disable Metrics/MethodLength
      # Ensure that the read list attributes are always Arrays of strings
      # List of lists from prompts/private_data.txt
      cleaned_attributes = attributes&.merge(
        noms: Array.wrap(attributes[:noms]).map(&:to_s).presence,
        adresses: Array.wrap(attributes[:adresses]).map(&:to_s).presence,
        telephones: Array.wrap(attributes[:telephones]).map(&:to_s).presence,
        raison_sociales: Array.wrap(attributes[:raison_sociales]).map(&:to_s).presence,
        sirets: Array.wrap(attributes[:sirets]).map(&:to_s).presence,
        ville_immatriculation_rcss: Array.wrap(attributes[:ville_immatriculation_rcss]).map(&:to_s).presence,
        numero_rcss: Array.wrap(attributes[:numero_rcss]).map(&:to_s).presence,
        rnes: Array.wrap(attributes[:rnes]).map(&:to_s).presence,
        assurances: Array.wrap(attributes[:assurances]).map(&:to_s).presence,
        numero_rge: Array.wrap(attributes[:numero_rge]).map(&:to_s).presence,
        emails: Array.wrap(attributes[:emails]).map(&:to_s).presence,
        numeros_tva: Array.wrap(attributes[:numeros_tva]).map(&:to_s).presence,
        ibans: Array.wrap(attributes[:ibans]).map(&:to_s).presence,
        uris: Array.wrap(attributes[:uris]).map(&:to_s).presence,
        client_noms_de_famille: Array.wrap(attributes[:client_noms_de_famille]).map(&:to_s).presence,
        client_prenoms: Array.wrap(attributes[:client_prenoms]).map(&:to_s).presence,
        client_civilite: Array.wrap(attributes[:client_civilite]).map(&:to_s).presence,
        client_adresses: Array.wrap(attributes[:client_adresses]).map(&:to_s).presence,
        pro_adresses: Array.wrap(attributes[:pro_adresses]).map(&:to_s).presence,
        forme_juridiques: Array.wrap(attributes[:forme_juridiques]).map(&:to_s).presence,
        capital_social: Array.wrap(attributes[:capital_social]).map(&:to_s).presence
      )&.compact.presence

      cleaned_attributes&.merge(
        client: {
          adresse: cleaned_attributes.dig(:client_adresses, 0),
          nom: cleaned_attributes.dig(:client_noms_de_famille, 0),
          prenom: cleaned_attributes.dig(:client_prenoms, 0),
          civilite: cleaned_attributes.dig(:client_civilite, 0)
        }.compact.presence,
        pro: {
          adresse: cleaned_attributes.dig(:pro_adresses, 0),
          numero_tva: cleaned_attributes.dig(:numeros_tva, 0)&.to_s,
          raison_sociale: cleaned_attributes.dig(:raison_sociales, 0),
          forme_juridique: cleaned_attributes.dig(:forme_juridiques, 0),
          assurance: cleaned_attributes.dig(:assurances, 0)&.to_s,
          capital: cleaned_attributes.dig(:capital_social, 0)&.to_s,
          rge_labels: cleaned_attributes&.fetch(:numero_rge, [])&.map(&:to_s),
          siret: cleaned_attributes.dig(:sirets, 0)&.to_s,
          rcs: cleaned_attributes.dig(:numero_rcss, 0)&.to_s,
          rcs_ville: cleaned_attributes.dig(:ville_immatriculation_rcss, 0),
          rne: cleaned_attributes.dig(:rnes, 0)&.to_s
        }.compact.presence
      )&.compact.presence
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def llm_read_attributes(llm) # rubocop:disable Metrics/MethodLength
      llm_klass = "Llms::#{llm.capitalize}".constantize
      return unless llm_klass.configured?

      processing_log = quote_file.start_processing_log("PrivateDataQa", "PrivateDataQa/#{llm_klass.name}") if quote_file

      llm = llm_klass.new(prompt, result_format: :json)
      begin
        llm.chat_completion(text)
      rescue Llms::Base::TimeoutError, llm_klass::ResultError => e
        ErrorNotifier.notify(e)
        raise QuoteReader::LlmError, e
      end

      begin
        @read_attributes = TrackingHash.new(
          TrackingHash.nilify_empty_values(llm.read_attributes)
        )
      ensure
        @result = llm.result
        raise QuoteReader::ReadError if @result.nil?

        @read_attributes = clean_attributes(@read_attributes)
      end

      quote_file.end_processing_log(processing_log) if processing_log

      read_attributes
    end
    # rubocop:enable Metrics/AbcSize

    def prompt
      Rails.root.join("lib/quote_reader/prompts/private_data.txt").read
    end
  end
end
