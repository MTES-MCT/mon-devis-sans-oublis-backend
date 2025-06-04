# frozen_string_literal: true

module QuoteReader
  # Read Quote text to extract Private data attributes by asking questions via LLM prompt online services
  class PrivateDataQa < Text
    VERSION = "0.0.1"

    attr_reader :read_attributes, :result

    def read
      @result = nil
      @read_attributes = {}

      return read_attributes if text.blank?

      llm_read_attributes
    end

    def version
      self.class::VERSION
    end

    private

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def llm_read_attributes # rubocop:disable Metrics/MethodLength
      return unless Llms::Albert.configured?

      llm = Llms::Albert.new(prompt, result_format: :json)
      begin
        llm.chat_completion(text)
      rescue Llms::Base::TimeoutError, Llms::Albert::ResultError => e
        ErrorNotifier.notify(e)
      end

      begin
        @read_attributes = TrackingHash.new(
          TrackingHash.nilify_empty_values(llm.read_attributes)
        )
      ensure
        @result = llm.result
        raise QuoteReader::ReadError if @result.nil?

        # Ensure that the read list attributes are always Arrays of strings
        # List of lists from prompts/private_data.txt
        @read_attributes = @read_attributes&.merge(
          noms: Array.wrap(@read_attributes[:noms]).map(&:to_s).presence,
          adresses: Array.wrap(@read_attributes[:adresses]).map(&:to_s).presence,
          telephones: Array.wrap(@read_attributes[:telephones]).map(&:to_s).presence,
          raison_sociales: Array.wrap(@read_attributes[:raison_sociales]).map(&:to_s).presence,
          sirets: Array.wrap(@read_attributes[:sirets]).map(&:to_s).presence,
          ville_immatriculation_rcss: Array.wrap(@read_attributes[:ville_immatriculation_rcss]).map(&:to_s).presence,
          numero_rcss: Array.wrap(@read_attributes[:numero_rcss]).map(&:to_s).presence,
          rnes: Array.wrap(@read_attributes[:rnes]).map(&:to_s).presence,
          assurances: Array.wrap(@read_attributes[:assurances]).map(&:to_s).presence,
          numero_rge: Array.wrap(@read_attributes[:numero_rge]).map(&:to_s).presence,
          emails: Array.wrap(@read_attributes[:emails]).map(&:to_s).presence,
          numeros_tva: Array.wrap(@read_attributes[:numeros_tva]).map(&:to_s).presence,
          ibans: Array.wrap(@read_attributes[:ibans]).map(&:to_s).presence,
          uris: Array.wrap(@read_attributes[:uris]).map(&:to_s).presence,
          client_noms_de_famille: Array.wrap(@read_attributes[:client_noms_de_famille]).map(&:to_s).presence,
          client_prenoms: Array.wrap(@read_attributes[:client_prenoms]).map(&:to_s).presence,
          client_civilite: Array.wrap(@read_attributes[:client_civilite]).map(&:to_s).presence,
          client_adresses: Array.wrap(@read_attributes[:client_adresses]).map(&:to_s).presence,
          pro_adresses: Array.wrap(@read_attributes[:pro_adresses]).map(&:to_s).presence,
          forme_juridiques: Array.wrap(@read_attributes[:forme_juridiques]).map(&:to_s).presence,
          capital_social: Array.wrap(@read_attributes[:capital_social]).map(&:to_s).presence
        )&.compact.presence

        @read_attributes = @read_attributes&.merge(
          client: {
            adresse: @read_attributes.dig(:client_adresses, 0),
            nom: @read_attributes.dig(:client_noms_de_famille, 0),
            prenom: @read_attributes.dig(:client_prenoms, 0),
            civilite: @read_attributes.dig(:client_civilite, 0)
          }.compact.presence,
          pro: {
            adresse: @read_attributes.dig(:pro_adresses, 0),
            numero_tva: @read_attributes.dig(:numeros_tva, 0)&.to_s,
            raison_sociale: @read_attributes.dig(:raison_sociales, 0),
            forme_juridique: @read_attributes.dig(:forme_juridiques, 0),
            assurance: @read_attributes.dig(:assurances, 0)&.to_s,
            capital: @read_attributes.dig(:capital_social, 0)&.to_s,
            rge_labels: @read_attributes&.fetch(:numero_rge, [])&.map(&:to_s),
            siret: @read_attributes.dig(:sirets, 0)&.to_s,
            rcs: @read_attributes.dig(:numero_rcss, 0)&.to_s,
            rcs_ville: @read_attributes.dig(:ville_immatriculation_rcss, 0),
            rne: @read_attributes.dig(:rnes, 0)&.to_s
          }.compact.presence
        )&.compact.presence
      end

      @read_attributes
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def prompt
      Rails.root.join("lib/quote_reader/prompts/private_data.txt").read
    end
  end
end
