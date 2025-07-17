# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/data_checks" do
  subject(:json) { response.parsed_body }

  describe "GET /api/v1/data_checks/geste_types" do
    before { get api_v1_data_checks_geste_types_url }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "returns a complete response" do
      expect(json.fetch("data")).to include(*QuoteCheck::GESTE_TYPES)
    end

    it "includes labels" do
      expect(json.dig("options", 1, "label")).to eq("Chauffe-eau solaire individuel")
    end
  end

  describe "GET /api/v1/data_checks/rge" do
    before { get api_v1_data_checks_rge_url, params: params }

    context "with SIRET, RGE and related date" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", date: "2024-07-08" } }

      it "returns a success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns valid" do
        expect(json.fetch("valid")).to be true
      end

      it "returns results" do
        expect(json.dig("results", 0, "domaine")).to eq("Ventilation mécanique")
      end

      it "does not return error" do
        expect(json).not_to have_key("error_details")
      end
    end

    context "with SIRET and Geste Type" do
      let(:params) { { siret: "52503410400014", geste_types: "vmc_double_flux" } }

      it "returns results" do
        expect(json.dig("results", 0, "domaine")).to eq("Ventilation mécanique")
      end
    end

    context "with SIRET, RGE and Geste Type" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", geste_types: "vmc_double_flux" } }

      it "returns results" do
        expect(json.dig("results", 0, "domaine")).to eq("Ventilation mécanique")
      end
    end

    context "with SIRET, RGE and matching Geste Types" do
      let(:params) do
        { siret: "52503410400014", rge: "Q90513", geste_types: "menuiserie_fenetre_toit,vmc_double_flux" }
      end

      it "returns results" do
        expect(json.dig("results", 0, "domaine")).to eq("Ventilation mécanique")
      end
    end

    context "with SIRET, RGE and unrelated Geste Types" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", geste_types: "isolation_plancher_bas" } }

      it "returns a not found error" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with SIRET, RGE and unknown Geste Types" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", geste_types: "abcd" } }

      it "returns a bad request error" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with SIRET but unrelated RGE" do
      let(:params) { { siret: "52503410400014", rge: "Q90514" } }

      it "returns an error with code" do # rubocop:disable RSpec/MultipleExpectations
        get api_v1_data_checks_rge_url, params: params
        expect(json.fetch("valid")).to be false
        expect(json.dig("error_details", 0, "code")).to eq("rge_non_correspondant")
      end
    end

    context "with SIRET and RGE but non corresponding date" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", date: "1990-10-01" } }

      it "returns an error with code" do # rubocop:disable RSpec/MultipleExpectations
        get api_v1_data_checks_rge_url, params: params
        expect(response).to have_http_status(:bad_request)
        expect(json.fetch("valid")).to be false
        expect(json.dig("error_details", 0, "code")).to eq("rge_hors_date")
      end
    end
  end
end
