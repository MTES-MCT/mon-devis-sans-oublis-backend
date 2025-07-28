# frozen_string_literal: true

module QuoteReader
  # Read Quote text to extract Quote attributes by asking questions via LLM prompt online services
  class Qa < Text
    DEFAULT_LLM = ENV.fetch("QA_DEFAULT_LLM", "mistral")
    VERSION = "0.0.1"

    attr_reader :read_attributes, :result

    def read(llm: nil)
      return {} if text.blank?

      llm_read_attributes(llm || DEFAULT_LLM)
    end

    private

    # According to prompts/qa.txt, the attributes should be cleaned
    def clean_attributes(attributes)
      attributes&.merge(
        numero_devis: Array.wrap(attributes[:numero_devis]).map(&:to_s).presence
      )&.compact.presence
    end

    # rubocop:disable Metrics/AbcSize
    def llm_read_attributes(llm) # rubocop:disable Metrics/MethodLength
      llm_klass = "Llms::#{llm.capitalize}".constantize
      return unless llm_klass.configured?

      processing_log = quote_file.start_processing_log("Qa", "Qa/#{llm_klass.name}") if quote_file

      llm = llm_klass.new(prompt)
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
      Rails.root.join("lib/quote_reader/prompts/qa.txt").read
    end
  end
end
