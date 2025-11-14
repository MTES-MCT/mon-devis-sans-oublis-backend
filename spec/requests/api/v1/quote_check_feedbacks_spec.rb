# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/quote_checks/:quote_check_id/feedbacks" do
  subject(:json) { response.parsed_body }

  let(:quote_check) { create(:quote_check, :invalid) }
  let(:validation_error_details_id) { quote_check.validation_error_details.first.fetch("id") }
  let(:quote_check_id) { quote_check.id }

  describe "POST /api/v1/quote_checks/:quote_check_id/feedbacks" do
    context "with global feedback" do
      let(:quote_check_feedback_params) do
        {
          rating: 2,
          email: "no-reply@example.com",
          comment: "FAUX"
        }
      end

      before do
        post api_v1_quote_check_feedbacks_url(quote_check_id: quote_check_id), params: quote_check_feedback_params,
                                                                               headers: api_key_header
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns a created response" do
        expect(response).to have_http_status(:created)
      end

      it "returns the QuoteCheckFeedback" do
        expect(json).to include(
          "quote_check_id" => quote_check_id,
          "rating" => 2
        )
      end

      it "does not return detail fields" do
        expect(json).not_to be_key("validation_error_details_id")
      end

      it "creates a QuoteCheckFeedback" do
        expect(QuoteCheckFeedback.find(json.fetch("id"))).to be_present
      end

      context "with wrong rating" do # rubocop:disable RSpec/NestedGroups
        it "returns a unprocessable entity response" do
          post api_v1_quote_check_feedbacks_url(quote_check_id: quote_check_id),
               params: quote_check_feedback_params.merge(rating: -1),
               headers: api_key_header
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "with detail feedback" do
      let(:quote_check_feedback_params) do
        {
          validation_error_details_id: validation_error_details_id,
          comment: "FAUX"
        }
      end

      before do
        post api_v1_quote_check_feedbacks_url(quote_check_id: quote_check_id), params: quote_check_feedback_params,
                                                                               headers: api_key_header
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns a created response" do
        expect(response).to have_http_status(:created)
      end

      it "returns the QuoteCheckFeedback" do
        expect(json).to include(
          "quote_check_id" => quote_check_id,
          "validation_error_details_id" => validation_error_details_id
        )
      end

      it "does not return global fields" do
        expect(json).not_to be_key("rating")
      end

      it "creates a QuoteCheckFeedback" do
        expect(QuoteCheckFeedback.find(json.fetch("id"))).to be_present
      end

      context "with wrong error details id" do # rubocop:disable RSpec/NestedGroups
        it "returns a unprocessable entity response" do
          post api_v1_quote_check_feedbacks_url(quote_check_id: quote_check_id),
               params: quote_check_feedback_params.merge(validation_error_details_id: "wrong"),
               headers: api_key_header
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
