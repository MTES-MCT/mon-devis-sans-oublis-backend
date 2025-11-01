# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/brevo" do
  let(:brevo_headers) do
    { Authorization: "Bearer #{ENV.fetch('RAILS_INBOUND_EMAIL_PASSWORD')}" }
  end

  let(:brevo_webhook_params) do
    {
      items: []
    }
  end

  describe "POST /api/v1/quote_checks/from_brevo_email" do
    it "returns a successful response" do
      post from_brevo_email_api_v1_quote_checks_path,
           params: brevo_webhook_params,
           headers: brevo_headers,
           as: :json
      expect(response).to be_successful
    end
  end
end
