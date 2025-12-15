# frozen_string_literal: true

require "rails_helper"

RSpec.describe RntValidatorService, type: :service do
  describe ".clean_xml_for_rnt" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:schema_version) { "0.1.0" }
    let(:lot_travaux) { "plancher_haut" }
    let(:usage_systeme) { "" }
    let(:reference_travaux) { "isolation_sous_rampants" }
    let(:cop) { "3.0" }
    let(:scop) { "4.0" }

    let(:raw_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rnt version="#{schema_version}">
            <projet_travaux>
                <donnees_contextuelles>
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
                        #{reference_travaux && (reference_travaux == '' ? '<reference_travaux/>' : "<reference_travaux>#{reference_travaux}</reference_travaux>")}
                        <cout/>
                        <caracteristiques_travaux>
                            <isolation_sous_rampants>
                                <resistance_isolant>6.05</resistance_isolant>
                                <surface_isolant>46</surface_isolant>
                                <fixation_isolant>autre</fixation_isolant>
                                <materiau_isolant>laine_de_roches</materiau_isolant>
                                <norme_resistance>nf_en_12667</norme_resistance>
                                <epaisseur_isolant>19.5</epaisseur_isolant>
                                <materiau_isolant_complement/>
                                <fixation_isolant_complement/>
                            </isolation_sous_rampants>
                        </caracteristiques_travaux>
                        #{defined?(added_elements) && added_elements}
                    </travaux>
                    <travaux>
                        <lot_travaux>systeme</lot_travaux>
                        <type_travaux>pac_air_eau</type_travaux>
                        <usage_systeme>chauffage_ecs</usage_systeme>
                        <reference_travaux>pac_air_eau_1</reference_travaux>
                        <cout>16000</cout>
                        <caracteristiques_travaux>
                            <pac_air_eau>
                                <efficacite_saisonniere>1.7</efficacite_saisonniere>
                                <classe_regulateur>viii</classe_regulateur>
                                <type_installation>installation_collective</type_installation>
                                <note_technique>true</note_technique>
                                <calorifugeage>false</calorifugeage>
                                <dispositif_reglage_equilibrage>false</dispositif_reglage_equilibrage>
                                <taux_couverture>0.90</taux_couverture>
                                <type_emetteur>autre</type_emetteur>
                                <niveau_temperature_emetteur>basse_temperature</niveau_temperature_emetteur>
                                <intensite_demarrage>45</intensite_demarrage>
                                <marque_pac>HydroHeat</marque_pac>
                                <reference_pac>HH-10K</reference_pac>
                                <marque_regulateur>RegulSys</marque_regulateur>
                                <reference_regulateur>RS-4.0</reference_regulateur>
                                <puissance>10</puissance>
                                <systeme_appoint_pac>autre</systeme_appoint_pac>
                                <systeme_appoint_complement>radiateurs electriques</systeme_appoint_complement>
                                <cop>#{cop}</cop>
                                <surface_chauffee>100</surface_chauffee>
                                <exclusion_ecs_uniquement>false</exclusion_ecs_uniquement>
                                <exclusion_pac_basse_temperature>true</exclusion_pac_basse_temperature>
                            </pac_air_eau>
                        </caracteristiques_travaux>
                    </travaux>
                    <travaux>
                        <lot_travaux>systeme</lot_travaux>
                        <type_travaux>pac_air_air</type_travaux>
                        <usage_systeme>chauffage_refroidissement</usage_systeme>
                        <reference_travaux>pac_air_air_1</reference_travaux>
                        <cout>8000</cout>
                        <caracteristiques_travaux>
                            <pac_air_air>
                                <surface_chauffee>100</surface_chauffee>
                                <scop>#{scop}</scop>
                                <norme_coefficient_performance>reglement_europeen_206_2012</norme_coefficient_performance>
                                <puissance>10</puissance>
                                <marque_pac>ThermoPAC</marque_pac>
                                <reference_pac>TP-14X</reference_pac>
                            </pac_air_air>
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
      expect(described_class.clean_xml_for_rnt(raw_xml)).to include("<surface_isolant>46</surface_isolant>")
    end

    it "removes empty lines" do
      cleaned_xml = described_class.clean_xml_for_rnt(raw_xml)
      cleaned_xml.lines.each do |line|
        expect(line.strip).not_to be_empty
      end
    end

    context "with unexpected elements" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:added_elements) do
        "<norme_efficacite_saisonniere>reglement_europeen_813_2013</norme_efficacite_saisonniere>"
      end

      it "removes unexpected elements" do
        expect(described_class.clean_xml_for_rnt(raw_xml)).not_to include("<norme_efficacite_saisonniere>")
      end
    end

    context "with unexpected elements for context" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:added_elements) do
        "<traitement_humidite>pare_vapeur_protection_humidite</traitement_humidite>"
      end

      it "removes unexpected elements for context" do
        expect(described_class.clean_xml_for_rnt(raw_xml)).not_to include("<traitement_humidite>")
      end
    end

    context "with missing reference_travaux" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:reference_travaux) { "" }

      it "add reference_travaux if missing" do
        expect(
          described_class.clean_xml_for_rnt(raw_xml)
        ).to include("<reference_travaux>travaux-1-isolation_sous_rampants</reference_travaux>")
      end
    end

    context "with systeme lot_travaux" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:lot_travaux) { "systeme" }
      let(:usage_systeme) { "refroidissement" }

      it "keeps usage_systeme as relevant" do
        expect(described_class.clean_xml_for_rnt(raw_xml)).to include("<usage_systeme>")
      end
    end

    context "without systeme lot_travaux" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:lot_travaux) { "plancher_haut" }
      let(:usage_systeme) { "refroidissement" }

      it "removes usage_systeme as not relevant" do
        expect(described_class.clean_xml_for_rnt(raw_xml).scan("<usage_systeme>").count).to be <= 2
      end
    end

    context "with double projet_travaux wrapper" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:raw_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <rnt version="#{schema_version}">
              <projet_travaux>
              <donnees_contextuelles>
                <contexte>devis</contexte>
              </donnees_contextuelles>
              <projet_travaux>
                <travaux_collection>
                    <travaux>
                      <type_travaux>isolation_sous_rampants</type_travaux>
                    </travaux>
                  </travaux_collection>
                </projet_travaux>
            </projet_travaux>
          </rnt>
        XML
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "removes inner projet_travaux but keeping else" do # rubocop:disable RSpec/ExampleLength
        cleaned_xml = described_class.clean_xml_for_rnt(raw_xml)
        doc = Nokogiri::XML(cleaned_xml)
        expect(doc.xpath("/rnt/projet_travaux/projet_travaux").count).to eq(0)
        expect(doc.xpath("/rnt/projet_travaux/donnees_contextuelles/contexte").text).to eq("devis")
        expect(
          doc.xpath("/rnt/projet_travaux/travaux_collection/travaux/type_travaux").text
        ).to eq("isolation_sous_rampants")
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "with percentage values" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:cop) { "300" }
      let(:scop) { "400%" }

      it "converts percentage value to float" do
        expect(described_class.clean_xml_for_rnt(raw_xml)).to include("<cop>3.0</cop>")
                                                          .and include("<scop>4.0</scop>")
      end
    end
  end

  describe ".complete_json_for_rnt" do
    let(:aide_financiere_collection) { %w[mpr_geste mpr_ampleur] }
    let(:rnt_version) { "0.3" }

    let(:json) do
      {
        "travaux_collection" => {
          "travaux" => []
        }
      }
    end
    let(:completed_json) do
      described_class.complete_json_for_rnt(
        json,
        aide_financiere_collection:,
        rnt_version:
      )
    end

    it "adds donnees_contextuelles if missing" do
      expect(completed_json["projet_travaux"]["donnees_contextuelles"]).to include(
        "version" => rnt_version,
        "aide_financiere_collection" => aide_financiere_collection
      )
    end

    it "keeps travaux_collection intact" do
      expect(completed_json["projet_travaux"]["travaux_collection"]).to eq(
        "travaux" => []
      )
    end
  end
end
