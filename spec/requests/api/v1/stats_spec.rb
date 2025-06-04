# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/stats" do
  subject(:json) { response.parsed_body }

  describe "GET /api/v1/stats" do
    it "returns a successful response" do
      get api_v1_stats_url
      expect(response).to be_successful
    end

    it "returns a complete response" do
      get api_v1_stats_url
      expect(json).to include(*StatsService.keys)
    end
  end
end
