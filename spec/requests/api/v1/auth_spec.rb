# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/auth_check" do
  describe "GET /api/v1/auth_check" do
    let(:json) { response.parsed_body }

    it "returns a successful response" do
      get api_v1_auth_check_url, headers: api_key_header
      expect(response).to be_successful
    end

    it "returns a complete response" do
      get api_v1_auth_check_url, headers: api_key_header
      expect(json.fetch("user")).to eq("TEST")
    end

    context "when the API key is invalid" do
      it "returns an unauthorized response" do
        get api_v1_auth_check_url, headers: { "Authorization" => "Bearer invalid_api_key" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
