# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckTimeout, type: :service do
  subject(:service) { described_class.new(quote_check) }

  let(:started_at) { 3.hours.ago }
  let(:quote_check) { create(:quote_check, :pending, started_at:) }

  describe "#check" do
    it "updates the quote check status to invalid if it has timed out" do
      expect { service.check }.to change { quote_check.reload.status }.from("pending").to("invalid")
    end

    it "saves validation error details when the quote check times out" do
      expect { service.check }.to change { quote_check.reload.validation_error_details }.from(nil).to be_present
    end

    context "when the quote check has not timed out" do
      let(:started_at) { 5.minutes.ago }

      it "does not change the status if the quote check has not timed out" do
        expect { service.check }.not_to(change { quote_check.reload.status })
      end
    end
  end
end
