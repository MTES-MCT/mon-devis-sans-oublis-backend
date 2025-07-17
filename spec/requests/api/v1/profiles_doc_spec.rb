# frozen_string_literal: true

require "swagger_helper"

describe "Profiles API" do
  path "/profiles" do
    get "Récupérer les profils disponibles" do
      tags "Profils"
      produces "application/json"

      response "200", "liste des profiles" do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   data: { type: "#/components/schemas/profile" }
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
