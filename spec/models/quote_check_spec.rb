# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheck do
  describe "validations" do
    let(:attributes) { create(:quote_check).attributes }

    describe "metadata" do
      it "allows nil" do
        expect(described_class.new(attributes.merge(metadata: nil))).to be_valid
      end

      it "allows {}" do
        expect(described_class.new(attributes.merge(metadata: {}))).to be_valid
      end

      it "allows {aides: [], gestes: []}" do
        expect(described_class.new(attributes.merge(metadata: { aides: [], gestes: [] }))).to be_valid
      end

      it "allows good values" do
        expect(described_class.new(attributes.merge(
                                     metadata: { aides: ["CEE"],
                                                 gestes: ["Remplacement des fenêtres ou porte-fenêtres"] }
                                   ))).to be_valid
      end

      it "does not allow bad values" do
        expect(described_class.new(attributes.merge(metadata: { aides: ["bad"], gestes: ["bad"] }))).not_to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".results_sent" do
      let!(:quote_check_with_results_sent) { create(:quote_check, results_sent_at: 1.day.ago) }
      let!(:quote_check_without_results_sent) { create(:quote_check, results_sent_at: nil) }

      it "returns quote checks where results were sent" do
        expect(described_class.results_sent).to include(quote_check_with_results_sent)
      end

      it "does not return quote checks where results were not sent" do
        expect(described_class.results_sent).not_to include(quote_check_without_results_sent)
      end
    end

    describe ".results_not_sent" do
      let!(:quote_check_with_results_sent) { create(:quote_check, results_sent_at: 1.day.ago) }
      let!(:quote_check_without_results_sent) { create(:quote_check, results_sent_at: nil) }

      it "returns quote checks where results were not sent" do
        expect(described_class.results_not_sent).to include(quote_check_without_results_sent)
      end

      it "does not return quote checks where results were sent" do
        expect(described_class.results_not_sent).not_to include(quote_check_with_results_sent)
      end
    end
  end
end
