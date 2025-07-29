# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteInputMetadata do
  let(:quote_check) { QuoteCheck.new }

  describe ".metadata_values" do
    # rubocop:disable RSpec/MultipleExpectations
    it "returns metadata values" do # rubocop:disable RSpec/ExampleLength
      expect(QuoteCheck.metadata_values).to be_a(Hash)
      expect(QuoteCheck.metadata_values).to include("aides", "gestes")

      expect(QuoteCheck.metadata_values.fetch("aides")).to include("MaPrimeRénov' parcours accompagné")

      expect(QuoteCheck.metadata_values.dig("gestes", 0)).to include("group" => "Chauffage")
      expect(
        QuoteCheck.metadata_values.dig("gestes", 0, "values")
      ).to include("Chaudière biomasse", "Chauffage solaire combiné")
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "#aides=" do
    it "sets metadata" do
      quote_check.aides = ["MaPrimeRénov' parcours accompagné"]
      expect(quote_check.metadata.fetch("aides")).to eq(["MaPrimeRénov' parcours accompagné"])
    end
  end

  describe "#gestes=" do
    it "sets metadata" do
      quote_check.gestes = ["Chauffage solaire combiné"]
      expect(quote_check.metadata.fetch("gestes")).to eq(["Chauffage solaire combiné"])
    end
  end
end
