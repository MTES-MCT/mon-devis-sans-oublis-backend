# frozen_string_literal: true

module QuoteReader
  # Anonymise Quote text
  class Shrinker
    class NotImplementedError < ::NotImplementedError; end

    FIELDS_TO_SHRINKED = %i[
      powered_by
      terms
    ].freeze

    def initialize(raw_text)
      @raw_text = raw_text
    end

    def shrinked_text(attributes = nil)
      return nil if @raw_text.nil?

      attributes ||= {
        powered_by: QuoteReader::NaiveText.find_powered_by(@raw_text),
        terms: QuoteReader::NaiveText.find_terms(@raw_text)
      }
      Anonymiser.replace_text_from_attributes(attributes, FIELDS_TO_SHRINKED, @raw_text)
    end
  end
end
