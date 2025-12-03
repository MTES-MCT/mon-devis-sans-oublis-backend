# frozen_string_literal: true

require "rails_helper"

RSpec.describe RntValidatorService, type: :service do
  describe ".clean_xml_for_rnt" do
    let(:lot_travaux) { "plancher_haut" }
    let(:usage_systeme) { "" }

    let(:raw_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rnt hashkey="string" id="string" version="string">
            <projet_travaux>
                <donnees_contextuelles>
                    <version>0.3</version>
                    <contexte>devis</contexte>
                    <usage_batiment>appartement_chauffage_individuel</usage_batiment>
                    <aide_financiere_collection>
                        <aide_financiere>mpr_geste</aide_financiere>
                        <aide_financiere>mpr_ampleur</aide_financiere>
                    </aide_financiere_collection>
                </donnees_contextuelles>
                <travaux_collection>
                    <travaux>
                        <lot_travaux>#{lot_travaux}</lot_travaux>
                        <type_travaux>isolation_sous_rampants</type_travaux>
                        #{usage_systeme && (usage_systeme == '' ? '<usage_systeme/>' : "<usage_systeme>#{usage_systeme}</usage_systeme>")}
                        <reference_travaux>isolation_sous_rampants</reference_travaux>
                        <cout/>
                        <caracteristiques_travaux>
                            <isolation_sous_rampants>
                                <resistance_isolant>6.05</resistance_isolant>
                                <surface_1solant>46</surface_1solant>
                                <fixation_isolant>autre</fixation_isolant>
                                <materiau_isolant>laine_de_roches</materiau_isolant>
                                <norme_resistance>nf_en_12667</norme_resistance>
                                <epaisseur_isolant>19.5</epaisseur_isolant>
                                <materiau_isolant_complement/>
                                <fixation_isolant_complement/>
                            </isolation_sous_rampants>
                        </caracteristiques_travaux>
                    </travaux>
                </travaux_collection>
            </projet_travaux>
        </rnt>
      XML
    end

    it "removes empty nodes" do
      expect(described_class.clean_xml_for_rnt(raw_xml)).not_to include("<materiau_isolant_complement/>")
    end

    it "keeps valued nodes" do
      expect(described_class.clean_xml_for_rnt(raw_xml)).to include("<surface_1solant>46</surface_1solant>")
    end

    context "with systeme lot_travaux" do
      let(:lot_travaux) { "systeme" }
      let(:usage_systeme) { "refroidissement" }

      it "keeps usage_systeme as relevant" do
        expect(described_class.clean_xml_for_rnt(raw_xml)).to include("<usage_systeme>")
      end
    end

    context "without systeme lot_travaux" do
      let(:lot_travaux) { "plancher_haut" }
      let(:usage_systeme) { "refroidissement" }

      it "removes usage_systeme as not relevant" do
        expect(described_class.clean_xml_for_rnt(raw_xml)).not_to include("<usage_systeme>")
      end
    end
  end
end
