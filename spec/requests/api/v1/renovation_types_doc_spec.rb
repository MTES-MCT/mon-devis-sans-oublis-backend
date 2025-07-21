# frozen_string_literal: true

require "swagger_helper"

describe "RenovationTypes API" do
  path "/renovation_types" do
    get "Récupérer les types de rénovations disponibles" do
      tags "Profils"
      produces "application/json"

      response "200", "liste des renovation_types" do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   data: { type: "#/components/schemas/renovation_type" }
                 },
                 options: {
                   type: :array,
                   data: { type: "#/components/schemas/option" }
                 }
               },
               required: ["data"]
        run_test!
      end
    end
  end
end
