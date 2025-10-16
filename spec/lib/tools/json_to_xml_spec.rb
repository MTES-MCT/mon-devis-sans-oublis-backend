# frozen_string_literal: true

require "rails_helper"

RSpec.describe JsonToXml, type: :service do
  describe ".convert" do
    # rubocop:disable RSpec/ExampleLength
    # rubocop:disable RSpec/MultipleExpectations

    context "with JSON Quote for RNT" do
      it "converts to XML as expected" do
        json = JSON.parse(
          <<-JSON
                { "rnt": {\n    "projet_travaux": {\n        "donnees_contextuelles": {\n            "version": "0.3",\n            "contexte": "devis",\n            "usage_batiment": "appartement_chauffage_individuel",\n            "aide_financiere_collection": {\n                "aide_financiere": [\n                    "mpr_geste"\n                ]\n            }\n        },\n        "travaux_collection": {\n            "travaux": [\n                {\n                    "lot_travaux": "systeme",\n                    "type_travaux": "pac_air_eau",\n                    "usage_systeme": "chauffage",\n                    "reference_travaux": "pac_air_eau",\n                    "cout": null,\n                    "caracteristiques_travaux": {\n                        "pac_air_eau": {\n                            "efficacite_saisonniere": 1.79,\n                            "classe_regulateur": "viii",\n                            "note_technique": true,\n                            "calorifugeage": true,\n                            "dispositif_reglage_equilibrage": true,\n                            "taux_couverture": null,\n                            "type_emetteur": null,\n                            "niveau_temperature_emetteur": "moyenne_temperature",\n                            "intensite_demarrage": null,\n                            "marque_pac": "Atlantic",\n                            "reference_pac": "Alféa Extensa A.I. 8 R32",\n                            "marque_regulateur": "Atlantic",\n                            "reference_regulateur": "Navilink A59 NB Classe V avec Cozytouch",\n                            "puissance": null,\n                            "reference_travaux_appoint": null,\n                            "systeme_appoint_pac": null,\n                            "systeme_appoint_complement": null,\n                            "cop": 4.5,\n                            "surface_chauffee": null,\n                            "type_installation": "installation_individuelle",\n                            "exclusion_ecs_uniquement": null,\n                            "exclusion_pac_basse_temperature": true\n                        }\n                    }\n                },\n                {\n                    "lot_travaux": "systeme",\n                    "type_travaux": "chauffe_eau_thermodynamique",\n                    "usage_systeme": "ecs",\n                    "reference_travaux": "chauffe_eau_thermodynamique",\n                    "cout": null,\n                    "caracteristiques_travaux": {\n                        "chauffe_eau_thermodynamique": {\n                            "type_cet": "autres_installations",\n                            "cop": 3.3,\n                            "norme_cop_cet": "en_16147",\n                            "efficacite_saisonniere": null,\n                            "marque_equipement": "Atlantic",\n                            "reference_equipement": "Calypso connecté 200L"\n                        }\n                    }\n                }\n            ]\n        }\n    }\n}\n}
          JSON
        )
        xml = described_class.convert(json.to_json, root_name: "rnt", root_attrs: { version: "0.3" })

        expect(xml).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
        expect(xml).to include("<rnt version=\"0.3\">")
        expect(xml).to include("<projet_travaux>")
        expect(xml).to include("<donnees_contextuelles>")
        expect(xml).to include("<version>0.3</version>")
        expect(xml).to include("<contexte>devis</contexte>")
        expect(xml).to include("<usage_batiment>appartement_chauffage_individuel</usage_batiment>")
        expect(xml).to include("<aide_financiere_collection>")
        expect(xml).to include("<aide_financiere>mpr_geste</aide_financiere>")
        expect(xml).to include("</aide_financiere_collection>")
        expect(xml).to include("</donnees_contextuelles>")
        expect(xml).to include("<travaux_collection>")
        expect(xml).to include("<travaux>")
      end
    end

    it "converts a simple JSON object to XML" do
      json = '{"name": "John", "age": 30, "city": "New York"}'
      xml = described_class.convert(json, root_name: "person")
      expect(xml).to include("<person>")
      expect(xml).to include("<name>John</name>")
      expect(xml).to include("<age>30</age>")
      expect(xml).to include("<city>New York</city>")
      expect(xml).to include("</person>")
    end

    it "converts a nested JSON object to XML" do
      json = '{"person": {"name": "John", "address": {"street": "123 Main St", "city": "New York"}}}'
      xml = described_class.convert(json, root_name: "data")
      expect(xml).to include("<data>")
      expect(xml).to include("<person>")
      expect(xml).to include("<name>John</name>")
      expect(xml).to include("<address>")
      expect(xml).to include("<street>123 Main St</street>")
      expect(xml).to include("<city>New York</city>")
      expect(xml).to include("</address>")
      expect(xml).to include("</person>")
      expect(xml).to include("</data>")
    end

    it "converts a JSON array to XML" do
      json = '{"people": [{"name": "John"}, {"name": "Jane"}]}'
      xml = described_class.convert(json, root_name: "data")
      expect(xml).to include("<data>")
      expect(xml).to include("<people>")
      expect(xml.scan("<name>John</name>").size).to eq(1)
      expect(xml.scan("<name>Jane</name>").size).to eq(1)
      expect(xml).to include("</people>")
      expect(xml).to include("</data>")
    end

    it "handles empty JSON objects" do
      json = "{}"
      xml = described_class.convert(json, root_name: "data")
      expect(xml).to include("<data/>")
    end

    it "handles empty JSON arrays" do
      json = "[]"
      xml = described_class.convert(json, root_name: "data")
      expect(xml).to include("<data/>")
    end

    it "handles mixed content in JSON" do
      json = '{"name": "John", "hobbies": ["reading", "traveling"], "address": {"street": "123 Main St", "city": "New York"}}' # rubocop:disable Layout/LineLength
      xml = described_class.convert(json, root_name: "person")
      expect(xml).to include("<person>")
      expect(xml).to include("<name>John</name>")
      expect(xml).to include("<hobbies>")
      expect(xml.scan("<hobbies>reading</hobbies>").size).to eq(1)
      expect(xml.scan("<hobbies>traveling</hobbies>").size).to eq(1)
      expect(xml).to include("</hobbies>")
      expect(xml).to include("<address>")
      expect(xml).to include("<street>123 Main St</street>")
      expect(xml).to include("<city>New York</city>")
      expect(xml).to include("</address>")
      expect(xml).to include("</person>")
    end

    # rubocop:enable RSpec/MultipleExpectations
    # rubocop:enable RSpec/ExampleLength
  end
end
