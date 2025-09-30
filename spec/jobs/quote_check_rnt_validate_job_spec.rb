# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckRntValidateJob do
  describe "#perform" do
    let(:quote_check) { create(:quote_check, anonymized_text: "Sample anonymized text") }

    it "validates the quote check and stores result in Kredis", :vcr do # rubocop:disable RSpec/ExampleLength
      described_class.new.perform(quote_check.id)

      cached_result = Kredis.json(described_class.cache_key(quote_check.id)).value
      expect(cached_result).to match(a_hash_including(
                                       "quote_check_rnt_xml" => a_string_starting_with("<rnt"),
                                       "rnt_validation_response" => a_hash_including(
                                         "validation_xsd" => a_hash_including("valid" => false)
                                       ),
                                       "quote_check_rnt_json" => a_hash_including("projet_travaux")
                                     ))
    end

    context "when QuoteCheck does not exist" do
      it "returns without error" do
        expect { described_class.new.perform("non-existent-id") }.not_to raise_error
      end
    end
  end
end
