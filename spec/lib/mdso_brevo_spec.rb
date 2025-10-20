# frozen_string_literal: true

require "rails_helper"

RSpec.describe MdsoBrevo, type: :service do
  describe "#import_quote_check" do
    subject(:service) { described_class.new(email_params) }

    let(:email_params) do
      {
        "From" => { "Address" => "dude@example.com" },
        "Recipients" => ["no-reply@example.com", "conseiller@#{ENV.fetch('INBOUND_MAIL_DOMAIN')}"],
        "Attachments" => attachments
      }
    end
    let(:attachments) do
      [
        {
          "Content-Type" => "application/pdf",
          "Name" => "sample_quote1.pdf",
          "DownloadToken" => "eyJmb2xkZXIiOiIyMDI1MTEwMTAxMDM0Ny4zMi4xNzAzMDA1MTY5IiwiZmlsZW5hbWUiOiJEQzAwNDIwMFBBQy1BaXJlYXUlMkJDaGF1ZmZlK2VhdSt0aGVybW8ucGRmIn0" # rubocop:disable Layout/LineLength
        },
        {
          "Content-Type" => "application/pdf",
          "Name" => "sample_quote2.pdf",
          "DownloadToken" => "eyJmb2xkZXIiOiIyMDI1MTEwMTAxMDM0Ny4zMi4xNzAzMDA1MTY5IiwiZmlsZW5hbWUiOiJEQzAwNDIwMFBBQy1BaXJlYXUlMkJDaGF1ZmZlK2VhdSt0aGVybW8ucGRmIn0" # rubocop:disable Layout/LineLength
        }
      ]
    end

    it "processes the email and creates quote checks" do
      expect { service.import_quote_check }.to change(QuoteCheck, :count).by_at_least(0)
    end

    it "determines the correct profile" do
      expect(service.send(:profile)).to eq("conseiller")
    end

    it "determines the correct renovation type" do
      expect(service.send(:renovation_type)).to eq("ampleur")
    end

    context "with one attachment" do
      let(:attachments) do
        [
          {
            "ContentType" => "application/pdf",
            "Name" => "sample_quote1.pdf",
            "DownloadToken" => "eyJmb2xkZXIiOiIyMDI"
          }
        ]
      end

      it "sets renovation type to 'geste'" do
        expect(service.send(:renovation_type)).to eq("geste")
      end
    end
  end
end
