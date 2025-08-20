# frozen_string_literal: true

require "rails_helper"

RSpec.describe MdsoApi, type: :service do
  describe "#validate_quote_check!" do
    subject(:result) { described_class.new.validate_quote_check!(quote_check_hash) }

    context "with complete quote_check" do
      let(:quote_check_hash) do
        QuoteCheckSerializer.new(QuoteCheck.new(profile: "artisan")).as_json.transform_keys(&:to_s)
                            .merge("id" => "1")
      end

      it "returns true" do
        expect(result).to be true
      end
    end

    context "with ETAS as null" do
      let(:quote_check_hash) do
        QuoteCheckSerializer.new(QuoteCheck.new(profile: "artisan")).as_json.transform_keys(&:to_s)
                            .merge(
                              "id" => "1",
                              "gestes" => [
                                {
                                  "id" => "1",
                                  "type" => "pac_air_air",
                                  "intitule" => "PAC air/air",
                                  "ETAS" => 127
                                },
                                {
                                  "id" => "2",
                                  "type" => "menuiserie_porte",
                                  "intitule" => "Porte d'entrée",
                                  "ETAS" => nil,
                                  "ud" => 0.82
                                }
                              ]
                            )
      end

      it "returns true" do
        expect(result).to be true
      end
    end

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
