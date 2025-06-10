# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Image::AlbertOcr, type: :service do
  subject(:albert_ocr) { described_class.new(quote_file.content, "image/png", quote_file:) }

  let(:file) { fixture_file_upload("quote_files/Devis_test.png") }
  let(:quote_file) { create(:quote_file, file:) }

  describe "#extract_text" do
    it "returns the content", :vcr do
      skip "Albert OCR is not working with images"
      expect(albert_ocr.extract_text).to include("Nice")
    end
  end
end
