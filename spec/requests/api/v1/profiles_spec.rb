# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/profiles" do
  subject(:json) { response.parsed_body }

  describe "GET /api/v1/profiles" do
    it "returns a successful response" do
      get api_v1_profiles_url
      expect(response).to be_successful
    end

    it "returns a complete response" do
      get api_v1_profiles_url
      expect(json.fetch("data")).to include(*QuoteCheck::PROFILES)
    end
  end
end
