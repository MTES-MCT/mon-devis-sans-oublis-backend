# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::PrivateDataQa, type: :service do
  describe ".json_schema" do
    subject(:json_schema) { described_class.json_schema }

    it "returns the JSON schema" do # rubocop:disable RSpec/MultipleExpectations
      expect(json_schema).to be_a(Hash)
      expect(json_schema).to have_key("type")
      expect(json_schema["type"]).to eq("object")
      expect(json_schema).to have_key("properties")
      expect(json_schema["properties"]).to be_a(Hash)
    end
  end

  describe ".prompt" do
    subject(:prompt) { described_class.send(:new, "Sample text").send(:prompt) }

    it "returns the generated prompt text" do
      expect(prompt).to eq(MdsoApiSchema.prompt_attributes)
    end

    it "matches the content of prompts/private_data.txt" do
      expect(prompt).to eq(Rails.root.join("lib/quote_reader/prompts/private_data.txt").read)
    end
  end

  describe "#read" do
    subject(:attributes) { described_class.new(text).read }

    context "when the text is nil" do
      let(:text) { nil }

      it { is_expected.to eq({}) }
    end

    context "when the text is empty" do
      let(:text) { "" }

      it { is_expected.to eq({}) }
    end
  end
end
