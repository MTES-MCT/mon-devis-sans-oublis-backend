# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/renovation_types" do
  subject(:json) { response.parsed_body }

  describe "GET /api/v1/renovation_types" do
    it "returns a successful response" do
      get api_v1_renovation_types_url
      expect(response).to be_successful
    end

    it "returns a complete response" do
      get api_v1_renovation_types_url
      expect(json.fetch("data")).to include(*QuoteCheck::RENOVATION_TYPES)
    end
  end
end
