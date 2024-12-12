# frozen_string_literal: true

# spec/controllers/posts_controller_spec.rb
require "rails_helper"

RSpec.describe "/api/v1/profiles" do
  describe "GET /api/v1/profiles" do
    let(:json) { response.parsed_body }

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
