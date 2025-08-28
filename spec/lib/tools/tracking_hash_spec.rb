# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackingHash, type: :service do
  describe ".nilify_empty_values" do
    # rubocop:disable RSpec/ExampleLength
    # rubocop:disable RSpec/MultipleExpectations
    it "removes empty values" do
      expect(described_class.nilify_empty_values(nil)).to be_nil
      expect(described_class.nilify_empty_values({})).to eq({})
      expect(described_class.nilify_empty_values([])).to eq([])

      expect(described_class.nilify_empty_values(
               {
                 a: { b: nil, c: "c", d: { e: nil, f: [nil, "f", ""], g: "" }, h: "", i: { j: "" } }
               },
               compact_array: false
             )).to eq(
               {
                 a: { b: nil, c: "c", d: { e: nil, f: [nil, "f", nil], g: nil }, h: nil, i: { j: nil } }
               }
             )

      expect(described_class.nilify_empty_values(
               {
                 a: { b: nil, c: "c", d: { e: nil, f: [nil, "f", ""], g: "" }, h: "", i: { j: "" } }
               },
               compact: true
             )).to eq(
               {
                 a: { c: "c", d: { f: ["f"] }, i: {} }
               }
             )
    end
    # rubocop:enable RSpec/MultipleExpectations
    # rubocop:enable RSpec/ExampleLength

    it "cleans Array" do
      expect(described_class.nilify_empty_values(
               { "e" => nil, "f" => [nil] }
             )).to eq({ "e" => nil, "f" => [] })
    end

    it "returns false for false values" do
      expect(described_class.nilify_empty_values({ key: false }).fetch(:key)).to be false
    end

    context "with compact option" do
      it "removes empty values" do
        expect(described_class.nilify_empty_values(
                 { "e" => nil, "f" => [nil] },
                 compact: true
               )).to eq({ "f" => [] })
      end
    end
  end

  describe "#[]" do
    it "works like a Hash" do
      hash = described_class.new(a: 1)
      expect(hash[:a]).to eq 1
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "works like an indifferent Hash" do
      expect(described_class.new(a: 1)["a"]).to eq 1
      expect(described_class.new("a" => 1)[:a]).to eq 1
      expect(described_class.new("a" => [1])[:a]).to eq [1]
    end
    # rubocop:enable RSpec/MultipleExpectations

    context "with an empty Hash and unknown key" do
      it "works as usual" do
        expect(described_class.new[:unknown_key]).to be_nil
      end
    end
  end

  describe "#dig" do
    context "with an empty Hash" do
      it "works as usual" do
        hash = described_class.new
        expect(hash.dig(nil)).to be_nil # rubocop:disable Style/SingleArgumentDig
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "works like with quotes and symbols" do
      hash = described_class.new(subhash_symbol: [{ "key" => 1 }])
      expect(hash.dig("subhash_symbol", 0, "key")).to eq 1
      expect(hash.dig(:subhash_symbol, 0, :key)).to eq 1
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "#keys_accessed" do
    it "returns the keys that have been accessed" do
      hash = described_class.new(a: 1, subhash: { b: 2 })
      hash[:a]
      hash[:subhash][:b]

      expect(hash.keys_accessed).to eq([:a, { subhash: [:b] }])
    end
  end
end
