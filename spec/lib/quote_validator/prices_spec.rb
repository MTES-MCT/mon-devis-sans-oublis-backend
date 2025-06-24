# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::Prices, type: :service do
  describe ".gestes_prices_ranges" do
    it "returns a hash of ranges" do
      expect(described_class.gestes_prices_ranges).to be_a(Hash)
    end

    it "returns Ruby range" do
      expect(described_class.gestes_prices_ranges(
               { geste_pas_cher: "10..20", geste_cher: "1000..2000" }.to_json
             )).to include("geste_cher" => 1000..2000)
    end
  end

  describe ".parse_generic_range" do
    subject(:range) { described_class.parse_generic_range(range_string) }

    context "with valid range" do
      let(:range_string) { "10..20" }

      it "parses the range correctly" do
        expect(described_class.parse_generic_range("10..20")).to eq(10..20)
      end
    end

    context "with invalid range separator" do
      let(:range_string) { "10-20" }

      it "raises an ArgumentError" do
        expect { range }.to raise_error(ArgumentError, /Invalid range format for 10-20/i)
      end
    end

    context "with invalid range number" do
      let(:range_string) { "10,2..20" }

      it "raises an ArgumentError" do
        expect { range }.to raise_error(ArgumentError, /invalid value for Integer\(\): "10,2"/i)
      end
    end
  end

  context "when validating quote check prices" do
    let(:env_json) { { geste_pas_cher: "10..20", geste_cher: "1000..2000" }.to_json }

    let(:validator) { described_class.new(attributes) }
    let(:attributes) do
      { gestes: [
        { type: "geste_pas_cher", price: 15.3 },
        { type: "geste_moyen_cher", price: 100.2 },
        { type: "geste_cher", price: 5_000 }
      ] }
    end

    before do
      allow(described_class).to receive(:gestes_prices_ranges).and_return(
        described_class.gestes_prices_ranges(env_json)
      )

      validator.validate!
    end

    describe "#control_codes" do
      it "returns control_codes" do
        expect(validator.control_codes).to include("geste_prix_inhabituel", "geste_prix_inhabituel")
      end
    end

    describe "#controls_count" do
      it "returns controls_count" do
        expect(validator.controls_count).to eq(2)
      end
    end

    describe "#errors" do
      it "returns errors" do
        expect(validator.errors).to include("geste_prix_inhabituel")
      end
    end

    describe "#error_details" do
      it "returns error_details" do
        expect(validator.error_details.dig(0, :code)).to eq("geste_prix_inhabituel")
      end
    end

    describe "#validate!" do
      it "returns validation" do
        expect(validator.validate!).to be false
      end
    end
  end
end
