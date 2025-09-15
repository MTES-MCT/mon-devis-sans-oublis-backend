# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llms::Albert, type: :service do
  subject(:albert) { described_class.new(prompt, json_schema:, model:) }

  let(:prompt) do
    "Retrouver les informations au format JSON {\"siret\": \"SIRET entreprise\", \"nom_entreprise\": \"Nom de l'entreprise\"}" # rubocop:disable Layout/LineLength
  end
  let(:model) { described_class::DEFAULT_MODEL } # Default
  let(:json_schema) { nil } # Default

  let(:text) { "Entreprise RenovPlus - 12345678900000" }

  describe "#chat_completion" do
    subject(:read_attributes) { albert.chat_completion(text) }

    context "with JSON schema" do
      let(:json_schema) { QuoteReader::PrivateDataQa.json_schema }

      it "returns a hash with the expected keys", :vcr do
        expect(read_attributes).to include(
          sirets: ["12345678900000"]
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
        expect(read_attributes.dig(
                 :projet_travaux, :travaux_collection, :travaux
               )).to include(
                 lot_travaux: "mur"
               )
      end
    end

    context "when model is not found" do
      let(:model) { "my_brain" }

      it "works as usual", :vcr do
        expect(read_attributes).to be_a(Hash)
      end

      it "fallbacks to best avalaible model", :vcr do
        read_attributes
        expect(albert.result.fetch("model")).to eq("meta-llama/Llama-3.1-8B-Instruct")
      end
    end
  end

  describe "#models" do
    it "returns the list of models", :vcr do
      expect(albert.models).to include(
        a_hash_including("aliases" => ["mistralai/Mistral-Small-3.1-24B-Instruct-2503"])
      )
    end
  end

  describe "#read_attributes" do
    let(:read_attributes) { albert.chat_completion(text) }

    before { read_attributes }

    it "returns the attributes", :vcr do
      expect(albert.read_attributes).to be(read_attributes)
    end
  end
end
