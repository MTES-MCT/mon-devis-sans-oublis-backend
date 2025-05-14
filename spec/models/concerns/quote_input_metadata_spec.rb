# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteInputMetadata do
  let(:quote_check) { QuoteCheck.new }

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
