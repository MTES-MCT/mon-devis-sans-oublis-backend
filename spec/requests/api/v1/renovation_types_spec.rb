# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/renovation_types" do
  subject(:json) { response.parsed_body }

  describe "GET /api/v1/renovation_types" do
    before { get api_v1_renovation_types_url }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns a complete response" do
      expect(json.fetch("data")).to include(*QuoteCheck::RENOVATION_TYPES)
    end

    it "includes labels" do
      expect(json.dig("options", 1, "label")).to eq("Rénovation d'ampleur")
    end
  end
end
