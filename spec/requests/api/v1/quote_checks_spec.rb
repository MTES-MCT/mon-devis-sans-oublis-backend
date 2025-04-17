# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/quote_checks" do
  let(:json) { response.parsed_body }

  before do
    ClamAv.download_database! unless ClamAv.database_exists?
  end

  describe "GET /api/v1/quote_checks/metadata" do
    it "returns a successful response" do
      get metadata_api_v1_quote_checks_url
      expect(response).to be_successful
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "returns the metadata" do # rubocop:disable RSpec/ExampleLength
      get metadata_api_v1_quote_checks_url
      expect(json.fetch("aides")).to include("CEE")
      expect(json.fetch("gestes")).to include({
                                                "group" => "Menuiserie",
                                                "values" => [
                                                  "Remplacement des fenêtres ou porte-fenêtres",
                                                  "Volet isolant"
                                                ]
                                              })
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "POST /api/v1/quote_checks" do
    let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
    let(:quote_check_params) do
      {
        file: file,
        profile: "artisan"
      }
    end

    it "returns a successful response" do
      post api_v1_quote_checks_url, params: quote_check_params, headers: basic_auth_header
      expect(response).to be_successful
    end

    it "returns a created response" do
      post api_v1_quote_checks_url, params: quote_check_params, headers: basic_auth_header
      expect(response).to have_http_status(:created)
    end

    it "returns a pending treatment response" do
      post api_v1_quote_checks_url, params: quote_check_params, headers: basic_auth_header
      expect(json.fetch("status")).to eq("pending")
    end

    it "creates a QuoteCheck" do
      expect do
        post api_v1_quote_checks_url, params: quote_check_params, headers: basic_auth_header
      end.to change(QuoteCheck, :count).by(1)
    end

    context "with parent_id" do
      let(:quote_check) { create(:quote_check) }
      let(:quote_check_params) do
        {
          file: file,
          profile: "artisan",
          parent_id: quote_check.id
        }
      end

      it "returns the parent_id" do
        post api_v1_quote_checks_url, params: quote_check_params, headers: basic_auth_header
        expect(json.fetch("parent_id")).to eq(quote_check.id)
      end
    end

    context "with file_text" do
      let(:quote_check) { create(:quote_check) }
      let(:quote_check_params) do
        {
          file: file,
          profile: "artisan",
          file_text: "Devis 12"
        }
      end

      it "uses the file_text provided" do
        post api_v1_quote_checks_url, params: quote_check_params, headers: basic_auth_header
        expect(QuoteCheck.find(json.fetch("id")).text).to eq("Devis 12")
      end
    end
  end

  describe "GET /api/v1/quote_checks/:id" do
    let(:quote_file) { create(:quote_file) }
    let(:quote_check) { create(:quote_check, file: quote_file) }

    before do
      QuoteCheckCheckJob.new.perform(quote_check.id)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "renders a successful response" do # rubocop:disable RSpec/ExampleLength
      get api_v1_quote_check_url(quote_check), as: :json, headers: basic_auth_header
      expect(response).to be_successful
      expect(json.fetch("status")).to eq("invalid")
      expect(json.fetch("error_details").first).to include({
                                                             code: "file_reading_error",
                                                             type: "error"
                                                           })
    end
    # rubocop:enable RSpec/MultipleExpectations

    context "with invalid file type" do
      let(:file) { Rails.root.join("spec/fixtures/files/quote_files/Devis_test.png").open }
      let(:quote_file) { create(:quote_file, file: file) }

      # rubocop:disable RSpec/MultipleExpectations
      it "returns a direct error response" do # rubocop:disable RSpec/ExampleLength
        get api_v1_quote_check_url(quote_check), as: :json, headers: basic_auth_header
        expect(response).to be_successful
        expect(json.fetch("status")).to eq("invalid")
        expect(json.fetch("errors")).to include("file_reading_error")
        expect(json.fetch("error_details").first).to include({
                                                               code: "file_reading_error",
                                                               type: "error"
                                                             })
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe "PATCH /api/v1/quote_checks/:id" do
    let(:quote_check) { create(:quote_check) }

    let(:quote_check_params) do
      {
        comment: "This is a comment"
      }
    end

    before do
      patch api_v1_quote_check_url(quote_check), params: quote_check_params, as: :json, headers: basic_auth_header
    end

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns the updated comment" do
      expect(json.fetch("comment")).to eq("This is a comment")
    end

    context "with large comment" do
      let(:quote_check_params) do
        {
          comment: "a" * 10_000
        }
      end

      it "returns an error response" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the error message" do
        expect(json.fetch("message")).to include(/Comment/i)
      end
    end

    context "with special characters" do
      let(:quote_check_params) do
        {
          comment: "<script>alert('XSS')</script> test < and >"
        }
      end

      it "returns the sanitized comment" do
        expect(json.fetch("comment")).to eq("alert('XSS') test &lt; and &gt;")
      end
    end
  end
end
