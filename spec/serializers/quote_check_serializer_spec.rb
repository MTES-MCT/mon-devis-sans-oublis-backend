# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteCheckSerializer, type: :serializer do
  subject(:serializer) { described_class.new(quote_check) }

  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  let(:quote_check) { create(:quote_check) }

  describe "serialization" do
    it "includes result_link" do
      expect(json["result_link"]).to eq(quote_check.frontend_webapp_url(mtm_campaign: "api"))
    end

    context "with geste_prices validation error" do
      before do
        quote_check.update!(
          validation_error_details: [
            {
              "id" => "f465ec8a-aada-4df0-98cb-e1d284c4226b-2",
              "code" => "geste_prix_inhabituel",
              "type" => "warning",
              "category" => "geste_prices",
              "geste" => { "type" => "geste_pas_cher", "price" => 15.3 },
              "provided_value" => "geste_pas_cher"
            },
            {
              "id" => "f465ec8a-aada-4df0-98cb-e1d284c4226b-1",
              "code" => "date_pre_visite_manquant",
              "type" => "warning",
              "title" => "La date de pré visite technique est fortement recommandée, notamment dans le cadre des CEE",
              "category" => "admin"
            },
            {
              "id" => "f465ec8a-aada-4df0-98cb-e1d284c4226b-f465ec8a-aada-4df0-98cb-e1d284c4226b-geste-2-2",
              "code" => "chauffe_eau_thermodynamique_type_installation_manquant",
              "type" => "missing",
              "title" => "Le type d'installation du chauffe-eau thermodynamique n'est pas indiqué",
              "category" => "gestes",
              "geste_id" => "f465ec8a-aada-4df0-98cb-e1d284c4226b-geste-2",
              "solution" =>
                "Le chauffe-eau thermodynamique est-il sur air extérieur, sur air extrait ou sur air ambiant?",
              "provided_value" => "Chauffe eau Thermodynamique Atlantic Calypso connecté 200L"
            }
          ]
        )
      end

      it "does not include geste_prices errors" do
        expect(json["error_details"].pluck("code")).not_to include("geste_prix_inhabituel")
      end

      it "includes other errors" do
        expect(json["error_details"].pluck("code")).to include(
          "date_pre_visite_manquant",
          "chauffe_eau_thermodynamique_type_installation_manquant"
        )
      end
    end
  end
end
