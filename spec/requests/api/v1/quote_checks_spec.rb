# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/quote_checks" do
  subject(:json) { response.parsed_body }

  let(:type_fichier) { "devis" }

  before do
    ClamAv.download_database! unless ClamAv.database_exists?

    stub_request(:post, /albert.+ocr/i)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "data" => [
            {
              "content" => "text"
            }
          ]
        }.to_json
      )
    stub_request(:post, /MDSO_OCR_HOST/i)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "text" => "text"
        }.to_json
      )

    stub_request(:post, /albert.+chat/i)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "choices" => [
            {
              "message" => {
                "content" => JSON.generate({ type_fichier: })
              }
            }
          ]
        }.to_json
      )

    stub_request(:post, /mistral.+chat/i)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "choices" => [
            {
              "message" => {
                "content" => JSON.generate({ version: "2.1.2" })
              }
            }
          ]
        }.to_json
      )
  end

  describe "GET /api/v1/quote_checks/metadata" do
    before { get metadata_api_v1_quote_checks_url }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns the aides metadata" do
      expect(json.fetch("aides")).to include("CEE")
    end

    it "returns the gestes metadata" do # rubocop:disable RSpec/ExampleLength
      expect(json.fetch("gestes")).to include({
                                                "group" => "Menuiserie",
                                                "values" => [
                                                  "Remplacement des fenêtres ou porte-fenêtres",
                                                  "Volet isolant",
                                                  "Menuiserie des fenêtres de toit",
                                                  "Menuiserie des portes"
                                                ]
                                              })
    end
  end

  describe "POST /api/v1/quote_checks" do
    let(:file) { fixture_file_upload("quote_files/Devis_test.pdf") }
    let(:quote_check_params) do
      {
        file: file,
        profile: "artisan",
        renovation_type: "geste"
      }
    end

    before { post api_v1_quote_checks_url, params: quote_check_params, headers: api_key_header }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns a created response" do
      expect(response).to have_http_status(:created)
    end

    it "returns a pending treatment response" do
      expect(json.fetch("status")).to eq("pending")
    end

    it "creates a QuoteCheck" do
      expect(QuoteCheck.find(json.fetch("id"))).to be_present
    end

    context "with case_id" do
      let(:quotes_case) { create(:quotes_case) }
      let(:quote_check_params) do
        {
          file: file,
          profile: "artisan",
          case_id: quotes_case.id
        }
      end

      it "reuses the renovation_type from case" do
        expect(QuoteCheck.find(json.fetch("id")).renovation_type).to eq(quotes_case.renovation_type)
      end

      context "with many QuoteChecks" do # rubocop:disable RSpec/NestedGroups
        before do
          create_list(:quote_check, QuotesCase::MAX_QUOTE_CHECKS - 1, case: quotes_case)
        end

        it "returns error on too many QuoteChecks" do # rubocop:disable RSpec/MultipleExpectations
          post api_v1_quote_checks_url, params: quote_check_params, headers: api_key_header

          expect(response).to have_http_status(:unprocessable_content)
          expect(json.fetch("message").first).to match(/Case n'est pas valide/i)
        end
      end
    end

    context "with parent_id" do
      skip "TODO: parent_id is not managed properly so currently hidden"

      let(:quote_check) { create(:quote_check) }
      let(:quote_check_params) do
        {
          file: file,
          profile: "artisan",
          renovation_type: "geste",
          parent_id: quote_check.id
        }
      end

      it "returns the parent_id" do
        expect(json.fetch("parent_id")).to eq(quote_check.id)
      end
    end

    context "with file_text" do
      let(:quote_check) { create(:quote_check) }
      let(:quote_check_params) do
        {
          file: file,
          profile: "artisan",
          renovation_type: "geste",
          file_text: "Devis 12"
        }
      end

      it "uses the file_text provided" do
        expect(QuoteCheck.find(json.fetch("id")).text).to eq("Devis 12")
      end
    end
  end

  describe "GET /api/v1/quote_checks/:id" do
    let(:quote_file) { create(:quote_file) }
    let(:process) { true }
    let(:quote_check) { create(:quote_check, file: quote_file) }

    before do
      QuoteCheckCheckJob.new.perform(quote_check.id) if process

      get api_v1_quote_check_url(quote_check), as: :json, headers: api_key_header
    end

    context "with file reading error" do
      let(:type_fichier) { "autre" }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns an invalid status" do
        expect(json.fetch("status")).to eq("invalid")
      end

      it "returns an error" do
        expect(json.fetch("errors")).to include("file_type_error")
      end

      it "returns an error_details" do
        expect(json.fetch("error_details").first).to include({
                                                               code: "file_type_error",
                                                               type: "error"
                                                             })
      end
    end

    context "with another source" do
      let(:quote_check) { create(:quote_check, file: quote_file, source_name: "another") }

      it "renders a not found" do
        expect(response).to have_http_status(:not_found)
      end

      context "with mdso user" do # rubocop:disable RSpec/NestedGroups
        it "renders a successful response" do
          get api_v1_quote_check_url(quote_check), as: :json, headers: api_key_mdso_header
          expect(response).to be_successful
        end
      end
    end

    context "with result_sent_at tracking" do
      let(:quote_check) { create(:quote_check, file: quote_file, result_sent_at: nil) }

      it "sets result_sent_at on first call when not pending" do
        expect(quote_check.reload.result_sent_at).to be_present
      end

      context "when result_sent_at is already set" do # rubocop:disable RSpec/NestedGroups
        let(:original_timestamp) { 1.day.ago }
        let(:quote_check) { create(:quote_check, file: quote_file, result_sent_at: original_timestamp) }

        it "does not update result_sent_at" do
          expect(quote_check.reload.result_sent_at).to be_within(1.second).of(original_timestamp)
        end
      end

      context "when quote_check is pending" do # rubocop:disable RSpec/NestedGroups
        let(:process) { false }
        let(:quote_check) { create(:quote_check, :pending, file: quote_file, result_sent_at: nil) }

        it "does not set result_sent_at" do
          expect(quote_check.reload.result_sent_at).to be_nil
        end
      end
    end
  end

  describe "GET /api/v1/quote_checks/:id/results" do
    let(:quote_file) { create(:quote_file) }
    let(:quote_check) { create(:quote_check, file: quote_file) }

    before do
      QuoteCheckCheckJob.new.perform(quote_check.id)

      get results_api_v1_quote_check_url(quote_check), headers: api_key_header
    end

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns content including error details" do
      expect(response.body).to include(quote_check.reload.validation_error_details.first["title"])
    end

    context "with text format" do
      skip "TODO: Fix StackLevel too deep"

      before do
        get results_api_v1_quote_check_url(quote_check, format: :txt), headers: api_key_header
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns content including error details" do
        expect(response.body).to include(quote_check.reload.validation_error_details.first["title"])
      end
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
      patch api_v1_quote_check_url(quote_check), params: quote_check_params, as: :json, headers: api_key_mdso_header
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
        expect(response).to have_http_status(:unprocessable_content)
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
