# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::NaiveText, type: :service do
  describe "#read" do
    subject(:attributes) { described_class.new(text).read }

    context "when the text is nil" do
      let(:text) { nil }

      it { is_expected.to eq({}) }
    end

    context "when the text is empty" do
      let(:text) { "" }

      it { is_expected.to eq({}) }
    end

    context "when the text is not empty" do
      let(:text) do
        <<~TEXT
          Devis
          Numero de devis : 1234

          Client
          Nom : Doe
          Prenom : John
          Adresse : 42 rue du Paradis
          Adresse Chantier : 43 rue du Paradis

          Pro
          Adresse Pro : 42 rue
          Raison Sociale : ACME
          Forme Juridique : SAS
          TVA : FR12345678911
          Capital : 1000 €
          Siret : 123456789
          RGE Number : E123456
        TEXT
      end

      it "fills the attributes" do # rubocop:disable RSpec/ExampleLength
        expect(attributes).to include(
          devis: "Devis",
          client: {},
          pro: {
            numero_tva: "FR12345678911",
            siret: nil
          }
        )
      end
    end
  end

  # rubocop:disable RSpec/MultipleExpectations

  describe ".find_adresses" do
    it "returns the adresse" do # rubocop:disable RSpec/ExampleLength
      expect(
        described_class.find_adresses("17 rue de l'union 94140 ALFORTVILLE")
      ).to eq(["17 rue de l'union 94140 ALFORTVILLE"])
      expect(
        described_class.find_adresses("17 rue de l'union\n94140 ALFORTVILLE")
      ).to eq(["17 rue de l'union\n94140 ALFORTVILLE"])
    end
  end

  describe ".find_adresse_chantier" do
    it "returns the adresse_chantier" do
      expect(
        described_class.find_adresse_chantier("17 rue de l'union 94140 ALFORTVILLE")
      ).to eq("17 rue de l'union 94140 ALFORTVILLE")
    end
  end

  describe ".find_adresse_pro" do
    it "returns the adresse_pro" do
      expect(
        described_class.find_adresse_pro("17 rue de l'union 94140 ALFORTVILLE")
      ).to eq("17 rue de l'union 94140 ALFORTVILLE")
    end
  end

  describe ".find_assurance" do
    it "returns the assurance" do
      expect(
        described_class.find_assurance("Assurance décennale : ToutRix couverture France n° contrat 0000010001234567")
      ).to eq("ToutRix couverture France n° contrat 0000010001234567")
    end
  end

  describe ".find_capital" do
    it "returns the capital" do
      expect(described_class.find_capital("capital de 12345 €")).to eq("12345")
      expect(described_class.find_capital("capilâide 12 345€")).to eq("12 345")
    end
  end

  describe ".find_ibans" do
    it "returns the ibans" do
      expect(
        described_class.find_ibans("IBAN : FR74 3000 1234 9000 0000 1234 P77")
      ).to eq(["FR74 3000 1234 9000 0000 1234 P77"])
    end
  end

  describe ".find_emails" do
    it "returns the emails" do
      expect(described_class.find_emails("no-reply@example.com")).to eq(["no-reply@example.com"])
    end
  end

  describe ".find_forme_juridique" do
    it "returns the forme_juridique" do
      expect(described_class.find_forme_juridique(" SAS ")).to eq("SAS")
      expect(described_class.find_forme_juridique(" SARL ")).to eq("SARL")
      expect(described_class.find_forme_juridique(" EURL ")).to eq("EURL")
      expect(described_class.find_forme_juridique(" E.U.R.L ")).to eq("E.U.R.L")
      expect(described_class.find_forme_juridique(" E.U.R.L. ")).to eq("E.U.R.L") # TODO: force the final dot if whished
    end
  end

  describe ".find_mention_devis" do
    it "returns the mention_devis" do
      expect(described_class.find_mention_devis("Devis")).to eq("Devis")
    end
  end

  describe ".find_numero_devis" do
    it "returns the numero_devis" do
      expect(described_class.find_numero_devis("Devis  N\"   ORG201234")).to eq("ORG201234")
      expect(described_class.find_numero_devis("Devis n° DC001234")).to eq("DC001234")
    end
  end

  describe ".find_numeros_tva" do
    it "returns the numeros_tva" do
      expect(described_class.find_numeros_tva("FRAB123456789")).to eq(["FRAB123456789"])
      expect(described_class.find_numeros_tva("FR12345678910")).to eq(["FR12345678910"])
      expect(described_class.find_numeros_tva("TVA  :FR10831861234")).to eq(["FR10831861234"])
      expect(described_class.find_numeros_tva("TVA intra FR86504321234")).to eq(["FR86504321234"])
      expect(described_class.find_numeros_tva("TVA intracommunautaire : FR86504321234")).to eq(["FR86504321234"])
    end
  end

  describe ".find_raison_sociale" do
    it "returns the raison_sociale" do
      expect(described_class.find_raison_sociale("SARL Super")).to eq("SARL Super")
      expect(described_class.find_raison_sociale("S.A.R.L Super")).to eq("S.A.R.L Super")
      expect(described_class.find_raison_sociale("EURL Super")).to eq("EURL Super")
      expect(described_class.find_raison_sociale("Super EURL")).to eq("Super EURL")
    end
  end

  describe ".find_rge_numbers" do
    it "returns the rge_numbers" do
      expect(described_class.find_rge_numbers("RGE  n. :E123456")).to eq(["E123456"])
      expect(described_class.find_rge_numbers("RGE n°E-E123456")).to eq(["E-E123456"])
      expect(described_class.find_rge_numbers("RE12345")).to eq(["RE12345"])
      expect(described_class.find_rge_numbers("E123456")).to eq(["E123456"])
      expect(described_class.find_rge_numbers("E-E123456")).to eq(["E-E123456"])
    end
  end

  describe ".find_label_numbers" do
    it "returns the label_numbers" do # rubocop:disable RSpec/ExampleLength
      expect(described_class.find_label_numbers("QB/74612")).to eq(["QB/74612"])
      expect(described_class.find_label_numbers("QS/51778")).to eq(["QS/51778"])
      expect(described_class.find_label_numbers("QPV/59641")).to eq(["QPV/59641"])
      expect(described_class.find_label_numbers("QPAC/59641")).to eq(["QPAC/59641"])
      expect(described_class.find_label_numbers("CPLUS/67225")).to eq(["CPLUS/67225"])
      expect(described_class.find_label_numbers("CPLUS/67225")).to eq(["CPLUS/67225"])
      expect(described_class.find_label_numbers("VPLUS/49707")).to eq(["VPLUS/49707"])
      expect(described_class.find_label_numbers("e\n  35630")).to eq([])
      expect(described_class.find_label_numbers("e  35630")).to eq(["e  35630"])
    end
  end

  describe ".find_powered_by" do
    it "returns the powered_by" do
      expect(
        described_class.find_powered_by("  Powered by TCPDF (www.tcpdf.org)   ")
      ).to eq(["Powered by TCPDF (www.tcpdf.org)"])
    end
  end

  describe ".find_rcss" do
    it "returns the rcss" do
      expect(described_class.find_rcss("RCS Nice B 987654321")).to eq(["RCS Nice B 987654321"])
      expect(described_class.find_rcss("RCS 987654321")).to eq(["RCS 987654321"])
    end
  end

  describe ".find_sirets" do
    it "returns the sirets" do
      expect(described_class.find_sirets("Siret : 12345678900000")).to eq(["12345678900000"])
      expect(described_class.find_sirets("Siret : 123 456 789 00000")).to eq(["123 456 789 00000"])
    end
  end

  describe ".find_telephones" do
    it "returns the telephone" do
      expect(described_class.find_telephones("01 23 45 67 89")).to eq(["01 23 45 67 89"])
      # expect(described_class.find_telephones("+331 23 45 67 89")).to eq(["+331 23 45 67 89"]) # TODO
      # expect(described_class.find_telephones("+33 1 23 45 67 89")).to eq(["+33 1 23 45 67 89"]) # TODO
      expect(described_class.find_telephones(" (33) 01 23 45 67 89")).to eq(["(33) 01 23 45 67 89"])
    end
  end

  describe ".find_terms" do
    let(:text) do
      <<~TEXT
        Page 4/4

        Powered by TCPDF (www.tcpdf.org)
                                                                               CONDITIONS GÉNÉRALES DE VENTE



        ARTICLE 1 -CHAMP D’APPLICATION


        Les présentes Conditions Générales de Vente s’appliquent sans restriction ni réserve à l’ensemble des ventes et prestations de services conclues par la société
      TEXT
    end

    it "returns the terms" do
      expect(
        described_class.find_terms(text).first
      ).to match(/^CONDITIONS GÉNÉRALES DE VENTE/)
    end
  end

  describe ".find_uris" do
    it "returns the uris" do
      expect(described_class.find_uris("http://perdu.com")).to eq(["http://perdu.com"])
      expect(described_class.find_uris("https://example.com/404/not_found")).to eq(["https://example.com/404/not_found"])
    end
  end

  # rubocop:enable RSpec/MultipleExpectations
end
