# frozen_string_literal: true

require "rails_helper"

return unless defined?(QuoteReader::Image::Tesseract)

RSpec.describe QuoteReader::Image::Tesseract, type: :service do
  let(:file) { fixture_file_upload("quote_files/Devis_test.png") }
  let(:content) { file.read }
  let(:quote_file) { create(:quote_file, file:) }

  describe "#extract_text" do
    it "returns the content" do
      expect(
        described_class.new(content, "image/png", quote_file:).extract_text
      ).to include("Nice")
    end
  end
end
