# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Image::MdsoOcr, type: :service do
  subject(:mdso_ocr) { described_class.new(quote_file.content, "image/png", quote_file:) }

  let(:file) { fixture_file_upload("quote_files/Devis_test.png") }
  let(:quote_file) { create(:quote_file, file:) }

  describe "#extract_text", :vcr do
    it "returns the content", :vcr do
      expect(mdso_ocr.extract_text).to include("Nice")
    end
  end

  describe "#models", :vcr do
    it "returns the list of models", :vcr do
      expect(mdso_ocr.models).to include("olmocr")
    end
  end
end
