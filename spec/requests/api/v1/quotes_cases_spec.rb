# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/quotes_cases" do
  let(:json) { response.parsed_body }

  describe "POST /api/v1/quotes_cases" do
    let(:quotes_case_params) { {} }

    it "returns a successful response" do
      post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header
      expect(response).to be_successful
    end

    it "returns a created response" do
      post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header
      expect(response).to have_http_status(:created)
    end

    it "returns an ID" do
      post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header
      expect(json.fetch("id")).to be_present
    end

    it "creates a QuotesCase" do
      expect do
        post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header
      end.to change(QuotesCase, :count).by(1)
    end

    context "with reference" do
      let(:reference) { "test-ref" }
      let(:quotes_case_params) do
        {
          reference: reference
        }
      end

      it "returns the reference" do
        post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header
        expect(json.fetch("reference")).to eq(reference)
      end
    end
  end
end
