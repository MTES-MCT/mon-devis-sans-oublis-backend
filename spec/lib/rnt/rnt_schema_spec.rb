# frozen_string_literal: true

require "rails_helper"

RSpec.describe RntSchema, type: :service do
  describe "#caracteristiques_travaux" do
    let(:type_travaux) { "ventilation_hybride_hygroreglable" }

    it "returns the caracteristiques travaux element for a given type travaux" do # rubocop:disable RSpec/ExampleLength
      caracteristiques = described_class.new.caracteristiques_travaux(type_travaux)
      expect(caracteristiques["type_bouches"]).to include(
        type: "enum",
        description: "type de bouches",
        enum: a_hash_including(
          "type_b" => "type b : les bouches d’extraction et les entrées d’air sont hygroréglables"
        )
      )
    end
  end

  describe "#prompt_travaux" do
    context "with a specific type" do
      it "returns a prompt string for specific travaux type and its caracteristiques" do # rubocop:disable RSpec/ExampleLength
        prompt = described_class.new.prompt_travaux(
          "ventilation_hybride_hygroreglable",
          "installation ventilation hybride hygroreglable"
        )
        expect(prompt).to eq(
          <<~PROMPT
            ### installation ventilation hybride hygroreglable :

            ```jsx
            {
            type_bouches: enum(type_a,type_b), type de bouches;
            nombre_appartements: int, nombre d'appartements (unité : sans unite);
            avis_technique_cstb: string, référence de l'avis technique CSTB;
            type_extracteur: enum(standard,basse_consommation), type d'extracteur (standard, basse consommation);
            puissance_extracteur: double, puissance de l'extracteur (unité : Wh/m3);
            marque_extracteur: string, nom de la marque de l'extracteur;
            reference_extracteur: string, reference de l'extrateur;
            presence_systeme: boolean, présence d'un extracteur, d'entrées d'air et de bouches d'extraction 0 : non 1 : oui;
            marque_bouches_extraction: string, nom de la marque des bouches d’extraction;
            reference_bouches_extraction: string, référence des bouches d’extraction;
            marque_entrees_air: string, marque des bouches d'entrées d’air;
            reference_entrees_air: string, référence des bouches d'entrées d’air;
            }
            ```
          PROMPT
        )
      end
    end

    context "with all types by default" do
      it "returns a prompt string for all travaux types and their caracteristiques" do # rubocop:disable RSpec/ExampleLength
        prompt = described_class.new.prompt_travaux
        expect(prompt).to include(
          <<~PROMPT
            ### installation ventilation hybride hygroreglable :

            ```jsx
            {
            type_bouches: enum(type_a,type_b), type de bouches;
            nombre_appartements: int, nombre d'appartements (unité : sans unite);
            avis_technique_cstb: string, référence de l'avis technique CSTB;
            type_extracteur: enum(standard,basse_consommation), type d'extracteur (standard, basse consommation);
            puissance_extracteur: double, puissance de l'extracteur (unité : Wh/m3);
            marque_extracteur: string, nom de la marque de l'extracteur;
            reference_extracteur: string, reference de l'extrateur;
            presence_systeme: boolean, présence d'un extracteur, d'entrées d'air et de bouches d'extraction 0 : non 1 : oui;
            marque_bouches_extraction: string, nom de la marque des bouches d’extraction;
            reference_bouches_extraction: string, référence des bouches d’extraction;
            marque_entrees_air: string, marque des bouches d'entrées d’air;
            reference_entrees_air: string, référence des bouches d'entrées d’air;
            }
            ```
          PROMPT
        )
      end
    end
  end

  describe "#types_travaux" do
    it "returns a hash of types travaux" do
      types = described_class.new.types_travaux
      expect(types).to include("isolation_combles_non_amenages" => "isolation des combles non aménagés")
    end
  end
end
