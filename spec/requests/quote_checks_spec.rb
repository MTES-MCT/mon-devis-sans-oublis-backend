# frozen_string_literal: true

require "rails_helper"

RSpec.describe "QuoteChecksController" do
  describe "POST /:profile/devis/verifier" do
    let(:profile) { "artisan" }
    let(:quote_file) { fixture_file_upload("quote_files/Devis_test.pdf") }

    context "when the params are provided" do
      # rubocop:disable RSpec/MultipleExpectations
      it "creates a QuoteCheck" do
        post "/#{profile}/devis/verifier", params: { quote_file: }

        puts "@@@ response.body: #{response.body}" # TODO: Remove this DEBUG line
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("12345678900000") # SIRET from the Devis
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
