# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::Global, type: :service do
  subject(:quote_validator) { described_class.new(quote_attributes) }

  let(:quote_attributes) do
    {}
  end

  describe "#control_codes" do
    before { quote_validator.validate! }

    it "returns control_codes" do
      expect(quote_validator.control_codes).to include("devis_manquant", "date_chantier_manquant")
    end
  end

  describe "#controls_count" do
    before { quote_validator.validate! }

    it "returns controls_count" do
      expect(quote_validator.controls_count).to eq(24)
    end
  end

  describe "#errors" do
    before { quote_validator.validate! }

    it "returns errors" do
      expect(quote_validator.errors).to include("devis_manquant")
    end
  end

  describe "#error_details" do
    before { quote_validator.validate! }

    it "returns error_details" do
      expect(quote_validator.error_details.dig(0, :code)).to eq("devis_manquant")
    end
  end

  describe "#validate!" do
    it "returns validation" do
      expect(quote_validator.validate!).to be false
    end

    context "with symbolized and stringified keys" do
      let(:quote_attributes) do
        {
          client: {
            nom: "DOE",
            prenom: "JANE"
          },
          "pro" => {
            numero_tva: "1234567890",
            "raison_sociale" => "ACME"
          }
        }
      end

      before { quote_validator.validate! }

      it "reads the keys" do # rubocop:disable RSpec/ExampleLength
        expect(quote_validator.errors).not_to include(
          "client_nom_manquant",
          "client_prenom_manquant",
          "pro_raison_sociale_manquant",
          "tva_manquant"
        )
      end
    end
  end
end
