# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Image::Tesseract, type: :service do
  let(:file) { fixture_file_upload("quote_files/Devis_test.png") }
  let(:content) { file.read }

  describe "#extract_text" do
    it "returns the content" do
      expect(
        described_class.new(content, "image/png").extract_text
      ).to include("Nice")
    end
  end
end
