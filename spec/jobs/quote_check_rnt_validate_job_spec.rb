# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckRntValidateJob, type: :job do
  describe "#perform" do
    let(:quote_check) { create(:quote_check, anonymized_text: "Sample anonymized text") }
    let(:rnt_validation_result) do
      {
        quote_check_rnt_json: { "some" => "json" },
        quote_check_rnt_xml: "<xml>data</xml>",
        rnt_validation_response: { "status" => "valid" }
      }
    end

    before do
      allow_any_instance_of(RntValidatorService).to receive(:validate).and_return(rnt_validation_result)
    end

    it "validates the quote check and stores result in Kredis" do
      described_class.new.perform(quote_check.id)

      cached_result = Kredis.json("rnt:#{quote_check.id}").value
      expect(cached_result).to eq(rnt_validation_result.deep_stringify_keys)
    end

    context "when QuoteCheck is not processable" do
      before do
        allow_any_instance_of(RntValidatorService).to receive(:validate)
          .and_raise(RntValidatorService::NotProcessableError, "Not processable")
      end

      it "logs the error and re-raises" do
        expect(Rails.logger).to receive(:error).with(/RNT validation failed for QuoteCheck/)
        expect { described_class.new.perform(quote_check.id) }
          .to raise_error(RntValidatorService::NotProcessableError)
      end
    end
  end
end
