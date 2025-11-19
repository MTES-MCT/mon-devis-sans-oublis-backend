# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckRntValidateJob do
  describe "#perform" do
    subject(:result) { described_class.new.perform(quote_check.id) }

    let(:quote_check) { create(:quote_check, anonymized_text: "Sample anonymized text") }
    let(:quote_check_id) { quote_check.id }

    it "returns results", :vcr do # rubocop:disable RSpec/ExampleLength
      expect(result).to match(a_hash_including(
                                "quote_check_rnt_xml" => a_string_starting_with("<rnt"),
                                "rnt_validation_response" => a_hash_including(
                                  "validation_xsd" => a_hash_including("valid" => false)
                                ),
                                "quote_check_rnt_json" => a_hash_including("projet_travaux")
                              ))
    end

    it "stores results", :vcr do
      expect { result }.to change { RntCheck.where(quote_check:).count }.by(1)
    end

    context "when QuoteCheck does not exist" do
      let(:quote_check_id) { "non-existent-id" }

      it "returns without error" do
        expect { result }.not_to raise_error
      end
    end
  end
end
