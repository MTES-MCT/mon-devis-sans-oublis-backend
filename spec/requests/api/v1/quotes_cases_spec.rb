# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/PendingWithoutReason
RSpec.describe "/api/v1/quotes_cases" do
  subject(:json) { response.parsed_body }

  describe "POST /api/v1/quotes_cases" do
    let(:profile) { QuoteCheck::API_PROFILES.first }
    let(:quotes_case_params) do
      {
        profile:,
        reference:
      }.presence
    end
    let(:reference) { nil }

    before { post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns a created response" do
      expect(response).to have_http_status(:created)
    end

    it "returns an ID" do
      expect(json.fetch("id")).to be_present
    end

    it "creates a QuotesCase" do
      expect(QuotesCase.find_by(id: json.fetch("id"))).to be_present
    end

    context "with deprecated profile" do
      let(:profile) { QuoteCheck::DEPRECATED_PROFILES.fetch(0) }

      it "returns a failed response" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error on invalid profile" do
        expect(json.fetch("message").first).to match(/Profile n'est pas inclus\(e\) dans la liste/i)
      end
    end

    context "with tech profile" do
      let(:profile) { QuoteCheck::TECH_PROFILES.fetch(0) }

      it "returns a failed response" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error on invalid profile" do
        expect(json.fetch("message").first).to match(/Profile n'est pas inclus\(e\) dans la liste/i)
      end
    end

    context "with reference" do
      let(:reference) { "test-ref" }

      it "returns the reference" do
        post api_v1_quotes_cases_url, params: quotes_case_params, headers: api_key_header
        expect(json.fetch("reference")).to eq(reference)
      end
    end
  end

  describe "GET /api/v1/quotes_cases/:id" do
    let(:quotes_case) { create(:quotes_case) }

    context "with some QuoteChecks" do
      before do
        create_list(:quote_check, 2, case: quotes_case)
        get api_v1_quotes_case_url(quotes_case), as: :json, headers: api_key_header
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns a found response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the QuotesCase" do
        expect(json.fetch("id")).to eq(quotes_case.id)
      end

      it "returns the QuoteChecks" do
        expect(json.fetch("quote_checks").count).to eq(2)
      end

      it "returns the QuoteChecks with correct attributes" do
        expect(json.fetch("quote_checks").first.keys).to include(
          "id", "case_id", "status",
          "filename"
        )
      end
    end

    context "with finished QuoteChecks" do
      before do
        create(:quote_check, :finished, case: quotes_case)
        get api_v1_quotes_case_url(quotes_case), as: :json, headers: api_key_header
      end

      it "sets result_sent_at for finished quote_checks" do
        finished_quote_check = quotes_case.quote_checks.first
        expect(finished_quote_check.reload.result_sent_at).to be_present
      end
    end

    context "with pending QuoteChecks" do
      before do
        create(:quote_check, :pending, case: quotes_case)
        get api_v1_quotes_case_url(quotes_case), as: :json, headers: api_key_header
      end

      it "does not set result_sent_at for pending quote_checks" do
        pending_quote_check = quotes_case.quote_checks.first
        expect(pending_quote_check.reload.result_sent_at).to be_nil
      end
    end
  end

  describe "GET /api/v1/quotes_cases/:id/results" do
    let(:quotes_case) { create(:quotes_case) }

    before do
      create_list(:quote_check, 2, case: quotes_case)
      get results_api_v1_quotes_case_url(quotes_case), headers: api_key_header
    end

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns content including error details" do
      expect(response.body).to include(
        quotes_case.quote_checks.first.validation_error_details&.first&.fetch(:message) ||
        "Aucune erreur à signaler"
      )
    end

    context "with text format" do
      # rubocop:disable RSpec/MultipleExpectations
      skip("TODO: Fix StackLevel too deep") do # rubocop:disable RSpec/ExampleLength
        before do
          get results_api_v1_quotes_case_url(quotes_case, format: :txt), headers: api_key_header
        end

        it "returns a successful response" do
          expect(response).to be_successful
        end

        it "returns content including error details" do
          expect(response.body).to include(
            quotes_case.quote_checks.first.validation_error_details&.first&.fetch(:message) ||
            "Aucune erreur à signaler"
          )
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
# rubocop:enable RSpec/PendingWithoutReason
