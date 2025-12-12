# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiretValidator, type: :service do
  describe ".valid?", :vcr do
    subject(:valid) { described_class.valid?(siret) }

    context "when the SIRET is known" do
      let(:siret) { "13002526500013" }

      it { is_expected.to be true }
    end

    context "when the SIRET is unknown" do
      let(:siret) { "12345678900000" }

      skip("External service is not fully reliable") do # rubocop:disable RSpec/PendingWithoutReason
        it { is_expected.to be false }
      end
    end
  end
end
