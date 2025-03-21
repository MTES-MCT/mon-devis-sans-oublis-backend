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

        @read_attributes = @read_attributes&.merge(
          client: {
            adresse: @read_attributes.dig(:client_adresses, 0),
            nom: @read_attributes.dig(:client_noms_de_famille, 0),
            prenom: @read_attributes.dig(:client_prenoms, 0),
            civilite: @read_attributes.dig(:client_civilite, 0)
          }.compact.presence,
          pro: {
            adresse: @read_attributes.dig(:pro_adresses, 0),
            numero_tva: @read_attributes.dig(:numeros_tva, 0),
            raison_sociale: @read_attributes.dig(:raison_sociales, 0),
            forme_juridique: @read_attributes.dig(:forme_juridiques, 0),
            assurance: @read_attributes.dig(:assurances, 0),
            capital: @read_attributes.dig(:capital_social, 0),
            rge_labels: @read_attributes&.fetch(:numero_rge, []),
            siret: @read_attributes.dig(:sirets, 0),
            rcs: @read_attributes.dig(:numero_rcss, 0),
            rcs_ville: @read_attributes.dig(:ville_immatriculation_rcss, 0),
            rne: @read_attributes.dig(:rnes, 0)
          }.compact.presence
        )&.compact.presence
      end

      @read_attributes
    end
    # rubocop:enable Metrics/AbcSize

    def prompt
      Rails.root.join("lib/quote_reader/prompts/private_data.txt").read
    end
  end
end
