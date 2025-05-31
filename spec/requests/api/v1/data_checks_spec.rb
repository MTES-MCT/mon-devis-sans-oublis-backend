# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/data_checks/rge" do
  describe "GET /api/v1/data_checks/rge" do
    let(:json) { response.parsed_body }

    context "with SIRET but unrelated RGE" do
      let(:params) { { siret: "52503410400014", rge: "Q90514" } }

      it "returns an error with code" do # rubocop:disable RSpec/MultipleExpectations
        get api_v1_data_checks_rge_url, params: params
        expect(json.fetch("valid")).to be false
        expect(json.dig("error_details", 0, "code")).to eq("rge_non_correspondant")
      end
    end
  end
end
