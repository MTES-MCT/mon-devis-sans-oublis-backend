# frozen_string_literal: true

module QuoteReader
  # Anonymise Quote text
  class Shrinker
    class NotImplementedError < ::NotImplementedError; end

    DEFAULT_FIELDS_TO_SHRINKED = %i[
      powered_by
      terms
    ].freeze

    attr_reader :fields_to_shrink

    def initialize(raw_text, fields_to_shrink = DEFAULT_FIELDS_TO_SHRINKED)
      @raw_text = raw_text
      @fields_to_shrink = fields_to_shrink
    end

    def shrinked_text(attributes = nil)
      return nil if @raw_text.nil?

      attributes ||= {
        powered_by: QuoteReader::NaiveText.find_powered_by(@raw_text),
        terms: QuoteReader::NaiveText.find_terms(@raw_text)
      }
      Anonymizer.replace_text_from_attributes(attributes, fields_to_shrink, @raw_text)
    end
  end
end
