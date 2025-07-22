# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteInputMetadata do
  let(:quote_check) { QuoteCheck.new }

  describe ".metadata_values" do
    it "returns metadata values" do # rubocop:disable RSpec/MultipleExpectations
      expect(QuoteCheck.metadata_values).to be_a(Hash)
      expect(QuoteCheck.metadata_values).to include("aides", "gestes")
      expect(QuoteCheck.metadata_values.fetch("aides")).to include("MaPrimeRénov' parcours accompagné")
      expect(QuoteCheck.metadata_values.dig("gestes", 0)).to include("group" => "Chauffage")
    end
  end

  describe "I18n quote_checks.metadata" do
    # rubocop:disable RSpec/MultipleExpectations
    it "is covered by geste_types" do # rubocop:disable RSpec/ExampleLength
      I18n.t("quote_checks.metadata").with_indifferent_access.fetch("gestes").each do |gestes_group|
        gestes_group.fetch("values").each do |geste|
          expect(I18n.t("quote_checks.geste_type.title").values).to include(geste)

          geste_key = I18n.t("quote_checks.geste_type.title").key(geste).to_s
          expect(QuoteCheck::GESTE_TYPES_GROUPS.fetch(gestes_group.fetch("group"))).to include(geste_key)
        end
      end
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
