# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckSerializer, type: :serializer do
  subject(:serializer) { described_class.new(quote_check) }

  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  describe "serialization" do
    context "when check timeout" do
      let(:quote_check) { create(:quote_check, started_at: 2.hours.ago) }

      it "has invalid status" do
        expect(json).to include("status" => "invalid")
      end

      it "add the timeout error" do
        expect(json.dig("error_details", 0)).to include(
          "code" => "server_timeout_error",
          "category" => "server"
        )
      end
    end
  end
end
