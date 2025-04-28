# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckService, type: :service do
  let(:tempfile) { fixture_file_upload("quote_files/Devis_test.pdf", "application/pdf") }
  let(:filename) { File.basename(tempfile.path) }
  let(:profile) { "artisan" }
  let(:source_name) { "test" }

  describe "#initialize" do
    subject(:init) { described_class.new(tempfile, filename, profile, source_name:) }

    it "creates a new quote check" do
      expect { init }.to change(QuoteCheck, :count).by(1)
    end

    context "when the profile is not valid" do
      let(:profile) { "invalid" }

      it "raises an error" do
        expect { init }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#check" do
    subject(:quote_check) { described_class.new(tempfile, filename, profile, source_name:).check }

    before do
      stub_request(:post, /albert\.api\.etalab\.gouv\.fr/)
        .to_return(status: 200, body: "{\"bad_file\": false }")
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "returns the completed quote check" do # rubocop:disable RSpec/ExampleLength
      expect(quote_check).to be_a(QuoteCheck)
      expect(quote_check.text).to be_a(String)
      expect(quote_check.anonymised_text).to be_a(String)
      expect(quote_check.read_attributes).to be_a(Hash)
      expect(quote_check.quote_valid?).to be_in([true, false])
      expect(quote_check.validation_errors).to include(*%w[
                                                         devis_manquant pro_raison_sociale_manquant
                                                         pro_forme_juridique_manquant capital_manquant
                                                         client_nom_manquant
                                                       ])

      # DEPRECTATED
      # expect(quote_check.read_attributes.dig(
      #          "pro", "siret"
      #        )).to eq("12345678900000")
    end
    # rubocop:enable RSpec/MultipleExpectations

    context "with an empty file" do
      let(:tempfile) { fixture_file_upload("quote_files/empty.pdf", "application/pdf") }

      it "creates the QuoteCheck with dedicated error" do
        expect { quote_check.validation_errors }.to raise_error(QuoteReader::NoFileContentError)
      end
    end

    context "with an unsupported content type" do
      let(:tempfile) { fixture_file_upload("quote_files/Devis_test.zip", "application/zip") }

      it "creates the QuoteCheck with dedicated error" do
        expect(quote_check.validation_errors).to include("unsupported_file_format")
      end
    end
  end
end
