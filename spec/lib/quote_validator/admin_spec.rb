# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::Admin, type: :service do
  subject(:validator) { described_class.new(attributes) }

  let(:attributes) { build(:quote_check_works_data_qa_attributes) }

  describe "#control_codes" do
    before { validator.validate! }

    it "returns control_codes" do
      expect(validator.control_codes).to include("devis_manquant", "date_chantier_manquant")
    end
  end

  describe "#controls_count" do
    before { validator.validate! }

    it "returns controls_count" do
      expect(validator.controls_count).to eq(24)
    end
  end

  describe "#errors" do
    before { validator.validate! }

    it "returns errors" do
      expect(validator.errors).to include("devis_manquant")
    end
  end

  describe "#error_details" do
    before { validator.validate! }

    it "returns error_details" do
      expect(validator.error_details.dig(0, :code)).to eq("devis_manquant")
    end
  end

  describe "#validate!" do
    it "returns validation" do
      expect(validator.validate!).to be false
    end

    context "with symbolized and stringified keys" do
      let(:attributes) do
        build(:quote_check_works_data_qa_attributes,
              client: {
                nom: "DOE",
                prenom: "JANE"
              },
              "pro" => {
                numero_tva: "1234567890",
                "raison_sociale" => "ACME"
              })
      end

      before { validator.validate! }

      it "stores errors" do # rubocop:disable RSpec/ExampleLength
        expect(validator.errors).not_to include(
          "client_nom_manquant",
          "client_prenom_manquant",
          "pro_raison_sociale_manquant",
          "tva_manquant"
        )
      end

      it "stores control codes" do # rubocop:disable RSpec/ExampleLength
        expect(validator.control_codes).to include(
          "devis_manquant",
          "client_nom_manquant",
          "client_prenom_manquant",
          "pro_raison_sociale_manquant",
          "tva_manquant"
        )
      end
    end
  end
end
