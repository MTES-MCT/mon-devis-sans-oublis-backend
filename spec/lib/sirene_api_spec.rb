# frozen_string_literal: true

require "rails_helper"

RSpec.describe SireneApi, type: :service do
  describe "#recherche", :vcr do
    subject(:result) { described_class.new.recherche(siret) }

    context "when the SIRET is known" do
      let(:siret) { "13002526500013" }

      it { is_expected.to be true }
    end

    context "when the SIRET is unknown" do
      let(:siret) { "12345678900000" }

      it { is_expected.to be false }
    end
  end
end
