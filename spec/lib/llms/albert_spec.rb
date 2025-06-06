# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llms::Albert, type: :service do
  subject(:albert) { described_class.new("Bonjour", model:) }

  let(:model) { nil } # Default

  describe "#chat_completion" do
    context "when model is not found" do
      let(:model) { "my_brain" }
      let(:response) { albert.chat_completion("Quel est le sens de la vie ? au format JSON {\"choix1\": \"text\"}") }

      before do
        response
      end

      it "works as usual", :vcr do
        expect(response).to be_a(Hash)
      end

      it "fallbacks to best avalaible model", :vcr do
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
end
