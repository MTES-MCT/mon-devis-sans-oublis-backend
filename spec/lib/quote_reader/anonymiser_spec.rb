# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteReader::Anonymiser, type: :service do
  describe "#anonymised_text" do
    # rubocop:disable RSpec/ExampleLength
    it "anonymises the text" do
      expect(
        described_class.new(
          "Devis\nNumero de devis : 1234\n\nClient\nNom : Doe\nPrenom : John\n1234,tel 0123456789 0123456788"
        ).anonymised_text
      )
        .to eq("Devis\nNumero de devis : 1234\n\nClient\nNom : NOM\nPrenom : John\n1234,tel TELEPHONET TELEPHONET")
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
