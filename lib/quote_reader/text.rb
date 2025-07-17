# frozen_string_literal: true

module QuoteReader
  # Read Quote text to extract Quote attributes
  class Text
    attr_reader :text, :read_attributes,
                :quote_file

    def initialize(text, quote_file: nil)
      @text = text
      @quote_file = quote_file
    end

    def read
      @read_attributes = {}
    end

    def version
      self.class::VERSION
    end
  end
end
