# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::QuotesCase, type: :service do
  subject(:validator) { described_class.new(attributes, quotes_case_id: quotes_case.id) }

  let(:quotes_case) do
    create(:quotes_case).tap do |quotes_case|
      create(:quote_check,
             case: quotes_case,
             read_attributes: { client_prenoms: "Marc", client_noms_de_famille: %w[Andrea Baptiste] })
      create(:quote_check,
             case: quotes_case,
             read_attributes: { client_prenoms: "Jean", client_noms_de_famille: %w[Baptise Chloé] })
    end
  end

  let(:attributes) do
    quotes_case.attributes.merge(
      "quote_checks" => quotes_case.quote_checks.map(&:attributes)
    )
  end

  describe "#control_codes" do
    before { validator.validate! }

    it "returns control_codes" do
      expect(validator.control_codes).to include("client_prenom_incoherent", "client_nom_incoherent")
    end
  end

  describe "#controls_count" do
    before { validator.validate! }

    it "returns controls_count" do
      expect(validator.controls_count).to eq(2)
    end
  end

  describe "#errors" do
    before { validator.validate! }

    it "returns errors" do
      expect(validator.errors).to include("client_prenom_incoherent")
    end
  end

  describe "#error_details" do
    before { validator.validate! }

    it "returns error_details" do
      expect(validator.error_details.dig(0, :code)).to eq("client_prenom_incoherent")
    end
  end

  describe "#validate!" do
    it "returns validation" do
      expect(validator.validate!).to be false
    end

    context "with symbolized and stringified keys" do
      let(:quotes_case) do
        create(:quotes_case).tap do |quotes_case|
          create(:quote_check,
                 case: quotes_case,
                 read_attributes: { "client_prenoms" => "Marc", client_noms_de_famille: %w[Andrea Baptiste] })
          create(:quote_check,
                 case: quotes_case,
                 read_attributes: { client_prenoms: ["Jean"], "client_noms_de_famille" => %w[Baptise Chloé] })
        end
      end

      before { validator.validate! }

      it "stores errors" do
        expect(validator.errors).to include(
          "client_prenom_incoherent"
        )
      end

      it "stores only errors" do
        expect(validator.errors).not_to include(
          "client_nom_incoherent",
          "client_adresse_incoherent"
        )
      end

      it "stores control codes" do
        expect(validator.control_codes).to include(
          "client_prenom_incoherent",
          "client_nom_incoherent"
        )
      end
    end
  end
end
