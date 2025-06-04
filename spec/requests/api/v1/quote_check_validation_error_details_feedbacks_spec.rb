# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/quote_checks/:quote_check_id/error_details/:validation_error_detail_id/feedbacks" do
  subject(:json) { response.parsed_body }

  let(:quote_check) { create(:quote_check, :invalid) }
  let(:validation_error_details_id) { quote_check.validation_error_details.first.fetch("id") }
  let(:quote_check_id) { quote_check.id }

  describe "POST /api/v1/quote_checks/:quote_check_id/error_details/:validation_error_detail_id/feedbacks" do
    let(:quote_check_feedback_params) do
      {
        comment: "FAUX"
      }
    end

    # rubocop:disable RSpec/ExampleLength
    it "returns a successful response" do
      post api_v1_quote_check_validation_error_detail_feedbacks_url(
        quote_check_id: quote_check_id,
        validation_error_detail_id: validation_error_details_id
      ), params: quote_check_feedback_params,
         headers: api_key_mdso_header
      expect(response).to be_successful
    end

    it "returns a created response" do
      post api_v1_quote_check_validation_error_detail_feedbacks_url(
        quote_check_id: quote_check_id,
        validation_error_detail_id: validation_error_details_id
      ), params: quote_check_feedback_params,
         headers: api_key_mdso_header
      expect(response).to have_http_status(:created)
    end

    it "returns the QuoteCheckFeedback" do
      post api_v1_quote_check_validation_error_detail_feedbacks_url(
        quote_check_id: quote_check_id,
        validation_error_detail_id: validation_error_details_id
      ), params: quote_check_feedback_params,
         headers: api_key_mdso_header
      expect(json.fetch("quote_check_id")).to eq(quote_check_id)
    end

    it "creates a QuoteCheckFeedback" do
      expect do
        post api_v1_quote_check_validation_error_detail_feedbacks_url(
          quote_check_id: quote_check_id,
          validation_error_detail_id: validation_error_details_id
        ), params: quote_check_feedback_params,
           headers: api_key_mdso_header
      end.to change(QuoteCheckFeedback, :count).by(1)
    end

    context "with wrong error details id" do
      it "returns a not found response" do
        post api_v1_quote_check_validation_error_detail_feedbacks_url(
          quote_check_id: quote_check_id,
          validation_error_detail_id: "wrong"
        ),
             params: quote_check_feedback_params,
             headers: api_key_mdso_header
        expect(response).to have_http_status(:not_found)
      end
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
