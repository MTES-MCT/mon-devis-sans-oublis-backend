# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Pdf, type: :service do
  let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
  let(:content) { file.read }

  describe "#extract_text" do
    it "returns the content" do
      expect(described_class.new(content).extract_text).to include("Nice")
    end
  end

  describe "#to_images" do
    let(:file) { fixture_file_upload("quote_files/Devis_multi_pages.pdf") }

    let(:images) { described_class.new(content).to_images }

    it "returns an array of images" do # rubocop:disable RSpec/MultipleExpectations
      expect(images).to all(be_a(String))
      expect(images.size).to be(2)
    end
  end
end
