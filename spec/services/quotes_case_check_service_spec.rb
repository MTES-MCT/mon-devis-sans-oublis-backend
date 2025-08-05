# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuotesCaseCheckService, type: :service do
  let(:quotes_case) do
    create(:quotes_case).tap do |quotes_case|
      create_list(:quote_check, 2, case: quotes_case)
    end
  end

  describe "#check" do
    subject(:checked_quotes_case) { described_class.new(quotes_case, save: false).check }

    it "returns the checked quote case" do
      expect(checked_quotes_case).to eq(quotes_case)
    end

    context "when the QuotesCase has already been checked" do
      before do
        quotes_case.update!(
          validation_errors: ["some error"],
          validation_error_details: { some: "details" },
          validation_version: "1.0.0"
        )
      end

      it "resets the check results" do # rubocop:disable RSpec/MultipleExpectations
        expect(checked_quotes_case.validation_errors).to eq([])
        expect(checked_quotes_case.validation_error_details).to eq([])
        expect(checked_quotes_case.validation_version).to eq("0.0.1")
      end
    end
  end
end
