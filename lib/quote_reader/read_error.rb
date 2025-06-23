# frozen_string_literal: true

module QuoteReader
  class ReadError < StandardError; end
  class LlmError < ReadError; end
end
