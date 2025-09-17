# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llms::Mistral, type: :service do
  subject(:mistral) { described_class.new(prompt, json_schema:, model:) }

  let(:prompt) { Rails.root.join("lib/quote_reader/prompts/works_data.txt").read }
  let(:model) { described_class::DEFAULT_MODEL } # Default
  let(:json_schema) { nil } # Default

  let(:text) do
    <<~TEXT
      1.1  dépose et enlèvement d'une chaudière gaz hors condensation                             1,00  U        0,00           0,00
        1.2  Pompe à chaleur AIR/EAU - moyenne température - Atlantic Alféa Extensa A.I. 8 R32 -    1,00  U    8 765,00       8 765,00

              6kW - classe énergétique chauffage A+++ - efficacité énergétique saisonnière chauffage
              avec sonde extérieure 179 % - SCOP 4.5 - niveau sonore intérieur / extérieur : 32/38 dB
    TEXT
  end

  describe ".usage_cost_price" do
    it "returns the cost in €" do
      expect(described_class.usage_cost_price(
               prompt_tokens: 252_620,
               completion_tokens: 21_037
             )).to eq(0.7)
    end
  end

  describe "#chat_completion" do
    subject(:read_attributes) { mistral.chat_completion(text) }

    context "with JSON schema" do
      let(:json_schema) { QuoteReader::WorksDataQa.json_schema }

      it "returns a hash with the expected keys", :vcr do
        expect(read_attributes.dig(:tva, -1)).to include(
          prix_ht_total: 8765.0
        )
      end
    end

    context "with RNT JSON schema" do
      let(:json_schema) do
        JsonOpenapi.make_schema_refs_inline!(
          JSON.parse(
            Rails.root.join("spec/fixtures/files/rnt_openapi_schema.json").read
          )
        ).dig("components", "schemas", "rnt")
      end

      it "returns a hash with the expected keys", :vcr do
        skip "Mistral can not handle the size of this schema"

        expect(read_attributes.dig(:tva, -1)).to include(
          prix_ht_total: 8765.0
        )
      end
    end

    it "returns a successful complete response", :vcr do
      expect(read_attributes.dig(:gestes, -1)).to include(
        type: "pac_air_eau",
        marque: "Atlantic",
        puissance: 6.0
      )
    end
  end

  describe "#read_attributes" do
    let(:read_attributes) { mistral.chat_completion(text) }

    before { read_attributes }

    it "returns the attributes", :vcr do
      expect(mistral.read_attributes).to be(read_attributes)
    end
  end
end
