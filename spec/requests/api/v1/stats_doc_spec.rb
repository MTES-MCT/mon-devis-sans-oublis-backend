# frozen_string_literal: true

require "swagger_helper"

describe "Stats API" do
  path "/stats" do
    get "Récupérer les stats" do
      operationId :getStats
      tags "Stats"
      produces "application/json"

      response "200", "liste des stats" do
        schema "$ref" => "#/components/schemas/stats"
        run_test!
      end
    end
  end
end
