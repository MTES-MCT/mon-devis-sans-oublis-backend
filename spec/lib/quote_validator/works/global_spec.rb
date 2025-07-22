# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::Works::Global, type: :service do
  subject(:validator) { described_class.new(attributes) }

  let(:attributes) do
    build(:quote_check_qa_attributes,
          gestes: [
            { type: "chauffe_eau_thermo" },
            { type: "isolation_comble_perdu" }
          ])
  end

  describe "#control_codes" do
    before { validator.validate! }

    it "returns control_codes" do
      expect(validator.control_codes).to include("geste_prix_ht_manquant", "geste_taux_tva_manquant")
    end
  end

  describe "#controls_count" do
    before { validator.validate! }

    it "returns controls_count" do
      expect(validator.controls_count).to eq(19)
    end
  end

  describe "#errors" do
    before { validator.validate! }

    it "returns errors" do
      expect(validator.errors).to include("geste_taux_tva_manquant")
    end
  end

  describe "#error_details" do
    before { validator.validate! }

    it "returns error_details" do
      expect(validator.error_details.dig(0, :code)).to eq("isolation_marque_manquant")
    end
  end

  describe "#validate!" do
    it "returns validation" do
      expect(validator.validate!).to be false
    end

    context "with symbolized and stringified keys" do
      let(:attributes) do
        build(:quote_check_qa_attributes,
              "gestes" => [
                { type: "chauffe_eau_thermo" },
                { "type" => "isolation_comble_perdu" }
              ])
      end

      before { validator.validate! }

      it "stores errors" do
        expect(validator.errors).to include(
          "geste_prix_ht_manquant"
        )
      end

      it "stores control codes" do
        expect(validator.control_codes).to include(
          "geste_prix_unitaire_ht_manquant",
          "chauffe_eau_thermodynamique_type_installation_manquant"
        )
      end
    end
  end

  describe "#validate_rge_geste" do
    it "returns validation" do
      expect(validator.validate!).to be false
    end

    context "with valid RGE but wrong geste types" do
      let(:attributes) do
        build(:quote_check_qa_attributes,
              pro: {
                rge_labels: ["Q90513"],
                siret: "52503410400014"
              },
              gestes: [
                { type: "chauffe_eau_thermo" },
                { type: "isolation_comble_perdu" }
              ])
      end

      before { validator.validate! }

      it "adds errors for non matching geste types" do
        expect(validator.errors).to include("geste_rge_non_correspondant")
      end
    end

    context "with valid but deprecated RGE and matching geste types" do
      let(:attributes) do
        build(:quote_check_qa_attributes,
              date_devis: "2018-10-01",
              pro: {
                rge_labels: ["Q90513"],
                siret: "52503410400014"
              },
              gestes: [
                { type: "chauffe_eau_thermo" }
              ])
      end

      before { validator.validate! }

      it "adds errors for non matching geste types" do
        expect(validator.errors).to include("geste_rge_hors_date")
      end
    end
  end
end
