# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class DataChecksController < BaseController
      def siret
        siret = params[:siret].gsub(/\s+/, "").strip

        raise BadRequestError, "SIRET is required" if siret.blank?
        raise BadRequestError, "SIRET must be 14 digits" unless siret.match?(QuoteReader::NaiveText::SIRET_REGEX)

        raise NotFoundError, "SIRET invalid" unless SireneApi.new.recherche(siret)

        render json: { siret: siret, valid: true }
      end
    end
  end
end
