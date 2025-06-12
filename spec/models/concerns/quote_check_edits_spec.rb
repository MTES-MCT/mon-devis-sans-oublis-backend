# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckEdits do
  let(:quote_check) { create(:quote_check, :invalid) }
  let(:validation_error_id) { quote_check.validation_error_details.first["id"] }

  describe "#comment_validation_error_detail!" do
    it "comments a validation error detail" do
      quote_check.comment_validation_error_detail!(validation_error_id, "miss understanding")

      expect(quote_check.validation_error_edits.fetch(validation_error_id)).to include(
        "comment" => "miss understanding"
      )
    end
  end

  describe "#commented?" do
    subject(:commented) { quote_check.commented? }

    context "when there is no comment" do
      it { is_expected.to be false }
    end

    context "when there is an comment" do
      before do
        quote_check.comment_validation_error_detail!(validation_error_id, "commented? test")
      end

      it { is_expected.to be true }
    end
  end

  describe "#delete_validation_error_detail" do
    it "deletes a validation error detail" do
      quote_check.delete_validation_error_detail!(validation_error_id, reason: "not_used")

      expect(quote_check.validation_error_edits.fetch(validation_error_id)).to include(
        "deleted" => true,
        "reason" => "not_used"
      )
    end
  end

  describe "#edited_at" do
    subject(:edited_at) { quote_check.edited_at }

    context "when there is no edition" do
      it { is_expected.to be_nil }
    end

    context "when there is an edition" do
      before do
        quote_check.comment_validation_error_detail!(validation_error_id, "edited_at test")
      end

      it { is_expected.to be_within(2.seconds).of(Time.zone.now) }
    end
  end

  describe "#readd_validation_error_detail" do
    before do
      quote_check.delete_validation_error_detail!(validation_error_id, reason: "not_used")
    end

    it "readds a validation error detail" do
      quote_check.readd_validation_error_detail!(validation_error_id)

      expect(quote_check.validation_error_edits).not_to be_key(validation_error_id)
    end
  end
end
