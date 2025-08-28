# frozen_string_literal: true

require "rails_helper"

RSpec.describe MdsoAdemeMapping, type: :service do
  describe ".ademe_geste_types" do
    subject(:ademe_geste_types) { described_class.ademe_geste_types(domaine:, nom_certificat:) }

    context "with only domaine" do
      let(:domaine) { "Ventilation mécanique" }
      let(:nom_certificat) { nil }

      it "returns the corresponding MDSO geste type" do
        expect(ademe_geste_types).to eq(%w[vmc_double_flux vmc_simple_flux])
      end
    end

    context "with only nom_certificat" do
      let(:domaine) { nil }
      let(:nom_certificat) { "Chauffage +" }

      it "returns the corresponding MDSO geste type" do
        expect(ademe_geste_types).to eq(%w[chauffe_eau_solaire_individuel chauffe_eau_thermo])
      end
    end

    context "with both domaine and nom_certificat" do
      let(:domaine) { "Ventilation mécanique" }
      let(:nom_certificat) { "Chauffage +" }

      it "returns the corresponding MDSO geste type" do
        expect(ademe_geste_types).to eq(
          %w[chauffe_eau_solaire_individuel chauffe_eau_thermo vmc_double_flux vmc_simple_flux]
        )
      end
    end
  end

  describe ".geste_types_with_certification" do
    it "returns all MDSO geste types with certification" do
      expect(described_class.geste_types_with_certification).to include(
        "isolation_thermique_par_exterieur_ITE",
        "chauffe_eau_solaire_individuel"
      )
    end
  end
end
