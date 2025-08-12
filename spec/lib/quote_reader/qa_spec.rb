# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Qa, type: :service do
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
