# frozen_string_literal: true

require "rails_helper"

RSpec.describe RgeValidator, type: :service do
  describe ".valid?" do
    subject(:valid) { described_class.valid?(**params) }

    context "with SIRET only and having an RGE" do
      let(:params) { { siret: "52503410400014" } }

      it { is_expected.to be true }
    end

    context "with SIRET and related RGE" do
      let(:params) { { siret: "52503410400014", rge: "Q90513" } }

      it { is_expected.to be true }
    end

    context "with SIRET and related RGE in data" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", date: "2024-07-08" } }

      it { is_expected.to be true }
    end

    context "with SIRET and related RGE but too early date" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", date: "1990-10-01" } }

      it "raises an ArgumentError" do # rubocop:disable RSpec/MultipleExpectations
        expect do
          valid
        end.to raise_error(RgeValidator::ArgumentError) { |error|
                 expect(error.error_code).to eq("rge_hors_date")
               }
      end
    end

    context "with SIRET and unrelated RGE" do
      let(:params) { { siret: "52503410400014", rge: "Q90514" } }

      it "raises an ArgumentError" do # rubocop:disable RSpec/MultipleExpectations
        expect do
          valid
        end.to raise_error(RgeValidator::ArgumentError) { |error|
                 expect(error.error_code).to eq("rge_non_correspondant")
               }
      end
    end

    # TODO
    # context "with RGE only" do
    #   context "when RGE is valid" do
    #     let(:params) { { rge: "Q90513" } }

    #     it { is_expected.to be true }
    #   end

    #   context "when RGE is invalid" do
    #     let(:params) { { rge: "Q90514" } }

    #     it { is_expected.to be false }
    #   end
    # end
  end
end
