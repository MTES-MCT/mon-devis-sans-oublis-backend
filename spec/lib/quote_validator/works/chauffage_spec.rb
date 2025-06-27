# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::Works::Chauffage, type: :service do
  subject(:validator) { described_class.new(attributes) }

  let(:attributes) { build(:quote_check_qa_attributes) }

  describe "#validate_pac" do
    let(:geste) do
      {
        index: 1
      }
    end

    it "returns validation" do
      expect(validator.validate_pac(geste).first).to include(
        category: "gestes",
        code: "chauffage_puissance_manquant",
        type: "missing"
      )
    end

    context "with symbolized and stringified keys" do
      let(:geste) do
        {
          index: 1,

          SCOP: 4.5,
          type: "pac_air_eau",
          unite: "U",
          marque: "Presque Gratuit",
          prix_ht: 1234.0,
          intitule: "Pompe à chaleur AIR/EAU - moyenne température",
          prix_ttc: 1295.7,
          quantite: 1.0,
          taux_tva: 5.5,
          puissance: 6.0,
          reference: "R2D2",
          numero_ligne: "1.2",
          prix_unitaire_ht: 1234.0,
          regime_temperature: "moyenne",
          type_fluide_frigorigene: "R32"
        }
      end

      before { validator.validate_pac(geste) }

      # rubocop:disable RSpec/MultipleExpectations
      it "stores errors" do # rubocop:disable RSpec/ExampleLength
        expect(validator.errors).to include(
          "chauffage_etas_manquant"
        )
        expect(validator.errors).not_to include(
          "chauffage_marque_manquant"
        )
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "stores control codes" do
        expect(validator.control_codes).to include(
          "chauffage_marque_manquant",
          "chauffage_etas_manquant"
        )
      end
    end
  end
end
