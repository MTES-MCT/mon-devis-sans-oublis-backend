# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveStorage::FixedPostgresqlController" do
  describe "GET /rails/active_storage/postgresql/:signed_id/*filename" do
    let(:filepath) { Rails.root.join("spec/fixtures/files/quote_files/Devis_test.png") }
    let(:quote_file) { create(:quote_file, filepath:) }

    context "when the params are provided" do
      # rubocop:disable RSpec/MultipleExpectations
      it "renders the file" do # rubocop:disable RSpec/ExampleLength
        url = Rails.application.routes.url_helpers.rails_blob_url(
          quote_file.file,
          expires_in: 3.minutes,
          host: "http://www.example.com"
        )
        get url

        expect(response).to have_http_status(:redirect)
        expect(response.headers["Location"]).to include("rails/active_storage/postgresql/")

        follow_redirect!
        expect(response.content_type).to eq("image/png")
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
