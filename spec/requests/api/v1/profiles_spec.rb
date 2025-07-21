# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/profiles" do
  subject(:json) { response.parsed_body }

  describe "GET /api/v1/profiles" do
    before { get api_v1_profiles_url }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns a complete response" do
      expect(json.fetch("data")).to include(*QuoteCheck::PROFILES)
    end

    it "includes labels" do
      expect(json.dig("options", 1, "label")).to eq("Particulier")
    end
  end
end
