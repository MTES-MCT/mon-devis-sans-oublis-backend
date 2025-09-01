# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Anonymizer, type: :service do
  describe "#anonymized_text" do
    subject(:anonymized_text) { described_class.new(raw_text).anonymized_text(attributes) }

    let(:attributes) do
      build(:quote_check_works_data_qa_attributes,
            {
              client: {
                nom: "Doe",
                prenom: "John"
              },
              telephones: %w[0123456789 0123456788]
            })
    end

    context "with text" do
      let(:raw_text) do
        "Devis\nNumero de devis : 1234\n\nClient\nNom : Doe\nPrenom : John\n1234,tel 0123456789 0123456788"
      end

      it "anonymizes the text" do
        expect(anonymized_text).to eq(
          "Devis\nNumero de devis : 1234\n\nClient\nNom : NOM\nPrenom : PRENOM\n1234,tel TELEPHONE TELEPHONE"
        )
      end

      context "with empty values" do # rubocop:disable RSpec/NestedGroups
        let(:attributes) do
          build(:quote_check_works_data_qa_attributes,
                {
                  client: {
                    nom: "Doe",
                    prenom: "John"
                  },
                  telephones: ["", "0123456789"]
                })
        end

        it "anonymizes the text" do
          expect(anonymized_text).to eq(
            "Devis\nNumero de devis : 1234\n\nClient\nNom : NOM\nPrenom : PRENOM\n1234,tel TELEPHONE 0123456788"
          )
        end
      end
    end

    context "when the text is empty" do
      let(:raw_text) { "" }

      it "returns empty" do
        expect(anonymized_text).to eq("")
      end
    end
  end
end
