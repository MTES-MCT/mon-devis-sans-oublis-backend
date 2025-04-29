# frozen_string_literal: true

require "rails_helper"

RSpec.describe MdsoApi, type: :service do
  describe "#validate_quote_check!" do
    subject(:result) { described_class.new.validate_quote_check!(quote_check_hash) }

    context "with null quote_check" do
      let(:quote_check_hash) { nil }

      it "raises an error" do
        expect { result }.to raise_error(described_class::InvalidResponse)
      end
    end

    context "with empty quote_check" do
      let(:quote_check_hash) { {} }

      it "raises an error" do
        expect { result }.to raise_error(described_class::InvalidResponse)
      end
    end

    context "with partial quote_check" do
      let(:quote_check_hash) { { "id" => "1" } }

      it "raises an error" do
        expect { result }.to raise_error(described_class::InvalidResponse, /missing required parameters: status/)
      end
    end
  end
end
