# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrevoApi, type: :service do
  describe "#download_inbound_email_attachment", :vcr do
    subject(:body) { described_class.new.download_inbound_email_attachment(download_token) }

    context "with a valid download token" do
      let(:download_token) do
        "eyJmb2xkZXIiOiIyMDI1MTEwMTAxMDM0Ny4zMi4xNzAzMDA1MTY5IiwiZmlsZW5hbWUiOiJEQzAwNDIwMFBBQy1BaXJlYXUlMkJDaGF1ZmZlK2VhdSt0aGVybW8ucGRmIn0" # rubocop:disable Layout/LineLength
      end

      it "returns the attachment content" do
        expect(body).to match(/^%PDF-/)
      end
    end

    context "with an invalid download token" do
      let(:download_token) { "invalid_download_token_example" }

      it "raises a BadRequestError" do
        expect { body }.to raise_error(BrevoApi::BadRequestError, /Download token is invalid/)
      end
    end
  end

  describe "#webhooks_list", :vcr do
    subject(:result) { described_class.new.webhooks_list }

    it "returns a list of webhooks" do
      expect(result).to be_an(Array)
    end
  end
end
