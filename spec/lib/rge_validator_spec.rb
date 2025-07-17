# frozen_string_literal: true

require "rails_helper"

RSpec.describe RgeValidator, type: :service do
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

  describe ".geste_types_for_rge" do
    subject(:geste_types_for_rge) { described_class.geste_types_for_rge(siret, rge) }

    let(:siret) { "52503410400014" }
    let(:rge) { "Q90513" }

    it "returns the corresponding MDSO geste types" do
      expect(geste_types_for_rge).to include("pac_hybride", "vmc_double_flux")
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

  describe ".valid?" do
    subject(:valid) { described_class.valid?(**params) }

    context "with SIRET only and having an RGE" do
      let(:params) { { siret: "52503410400014" } }

      it { is_expected.to be_truthy }
    end

    context "with SIRET and related RGE" do
      let(:params) { { siret: "52503410400014", rge: "Q90513" } }

      it { is_expected.to be_truthy }
    end

    context "with SIRET and related RGE in date" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", date: "2024-07-08" } }

      it { is_expected.to be_truthy }
    end

    context "with SIRET only and unknown Geste Type" do
      let(:params) { { siret: "52503410400014", geste_types: %w[chauffe_eau_thermo abcd] } }

      it "raises an ArgumentError" do # rubocop:disable RSpec/MultipleExpectations
        expect do
          valid
        end.to raise_error(RgeValidator::ArgumentError) { |error|
                 expect(error.error_code).to eq("geste_type_inconnu")
               }
      end
    end

    context "with SIRET only and releated Geste Type" do
      let(:params) { { siret: "52503410400014", geste_types: %w[menuiserie_fenetre_toit vmc_double_flux] } }

      it { is_expected.to be_truthy }

      it "returns results" do
        expect(valid.first["domaine"]).to eq("Ventilation mécanique")
      end
    end

    context "with SIRET only and unreleated Geste Type" do
      let(:params) { { siret: "52503410400014", geste_types: "menuiserie_fenetre_toit" } }

      it { is_expected.to be_falsey }
    end

    context "with SIRET and related RGE but too early date" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", date: "1990-10-01" } }

      it "raises an ArgumentError" do # rubocop:disable RSpec/MultipleExpectations
        expect do
          valid
        end.to raise_error(RgeValidator::ArgumentError) { |error|
                 expect(error.error_code).to eq("rge_hors_date")
               }
      end
    end

    context "with SIRET and related RGE with good date" do
      let(:params) { { siret: "50432740400035", date: "20/07/2023" } }

      it { is_expected.to be_truthy }
    end

    context "with SIRET and unrelated RGE" do
      let(:params) { { siret: "52503410400014", rge: "Q90514" } }

      it "raises an ArgumentError" do # rubocop:disable RSpec/MultipleExpectations
        expect do
          valid
        end.to raise_error(RgeValidator::ArgumentError) { |error|
                 expect(error.error_code).to eq("rge_non_correspondant")
               }
      end
    end

    # TODO
    # context "with RGE only" do
    #   context "when RGE is valid" do
    #     let(:params) { { rge: "Q90513" } }

    #     it { is_expected.to be true }
    #   end

    #   context "when RGE is invalid" do
    #     let(:params) { { rge: "Q90514" } }

    #     it { is_expected.to be false }
    #   end
    # end
  end
end
