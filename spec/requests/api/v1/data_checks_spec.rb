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
      expect(json.dig("options", 1)).to include(
        "group" => "Chauffage",
        "label" => "Chauffage solaire combiné",
        "value" => "systeme_solaire_combine"
      )
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

      # Vérification du log de succès
      it "creates a processing log for successful request" do
        expect(ProcessingLog.count).to eq(1)
      end

      # Vérification des headers HTTP loggés
      it "logs HTTP headers correctly" do
        log = ProcessingLog.last
        expect(log.input_parameters).to have_key("user_agent")
      end
    end

    context "with SIRET and Geste Type" do
      let(:params) { { siret: "52503410400014", geste_types: "vmc_double_flux" } }

      it "returns results" do
        expect(json.dig("results", 0, "domaine")).to eq("Ventilation mécanique")
      end

      # Log avec geste_types
      it "logs geste_types parameter correctly" do
        log = ProcessingLog.last
        expect(log.input_parameters["geste_types"]).to eq(["vmc_double_flux"])
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

      # Log avec multiples geste_types
      it "logs multiple geste_types correctly" do
        log = ProcessingLog.last
        expect(log.input_parameters["geste_types"]).to eq(%w[menuiserie_fenetre_toit vmc_double_flux])
      end
    end

    context "with SIRET, RGE and unrelated Geste Types" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", geste_types: "isolation_plancher_bas" } }

      it "returns a not found error" do
        expect(response).to have_http_status(:not_found)
      end

      # Log d'erreur RGE manquant
      it "creates a processing log for rge_manquant error" do
        expect(ProcessingLog.last.output_result["error_code"]).to eq("rge_manquant")
      end
    end

    context "with SIRET, RGE and unknown Geste Types" do
      let(:params) { { siret: "52503410400014", rge: "Q90513", geste_types: "abcd" } }

      it "returns a bad request error" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Log d'erreur geste_type inconnu
      it "creates a processing log for unknown geste_type error" do
        expect(ProcessingLog.last.output_result["error_code"]).to eq("geste_type_inconnu")
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

      # Log d'erreur de date
      it "creates a processing log for date error" do
        expect(ProcessingLog.last.output_result["error_code"]).to eq("rge_hors_date")
      end
    end

    # Tests processing logs
    context "when testing logging behavior" do
      let(:params) { { siret: "52503410400014", rge: "Q90513" } }

      it "creates exactly one log per request" do
        expect { get api_v1_data_checks_rge_url, params: params }.to change(ProcessingLog, :count).by(1)
      end

      it "logs request timing" do
        get api_v1_data_checks_rge_url, params: params
        expect(ProcessingLog.last.started_at).to be_present
      end

      it "handles logging errors gracefully" do
        allow(ProcessingLog).to receive(:create!).and_raise(StandardError, "DB error")
        expect { get api_v1_data_checks_rge_url, params: params }.not_to raise_error
      end
    end

    # Tests avec différents User-Agents
    context "with different user agents" do
      let(:params) { { siret: "52503410400014", rge: "Q90513" } }

      before { ProcessingLog.destroy_all }

      it "logs curl user agent" do
        get api_v1_data_checks_rge_url, params: params, headers: { "User-Agent" => "curl/7.68.0" }

        log = ProcessingLog.last
        expect(log.input_parameters["user_agent"]).to eq("curl/7.68.0")
      end

      it "logs swagger user agent" do
        get api_v1_data_checks_rge_url, params: params, headers: { "User-Agent" => "Swagger-UI/4.15.5" }

        log = ProcessingLog.last
        expect(log.input_parameters["user_agent"]).to eq("Swagger-UI/4.15.5")
      end

      it "logs browser user agent" do
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        get api_v1_data_checks_rge_url, params: params, headers: { "User-Agent" => user_agent }

        log = ProcessingLog.last
        expect(log.input_parameters["user_agent"]).to eq(user_agent)
      end

      it "logs referer when present" do
        referer = "https://mon-devis-sans-oublis.beta.gouv.fr/verification-rge"
        get api_v1_data_checks_rge_url, params: params, headers: { "Referer" => referer }

        log = ProcessingLog.last
        expect(log.input_parameters["referer"]).to eq(referer)
      end
    end
  end
end
