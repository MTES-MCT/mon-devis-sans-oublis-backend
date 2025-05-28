# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class DataChecksController < BaseController
      def siret
        siret = params[:siret]

        begin
          raise NotFoundError, "SIRET invalid" unless SiretValidator.valid?(siret)
        rescue SiretValidator::ArgumentError => e
          raise BadRequestError, e
        end

        render json: { siret: siret, valid: true }
      end

      def rge
        siret = SiretValidator.validate_format!(params[:siret])
        rge = RgeValidator.validate_format!(params[:rge]) if params[:rge].present?

        if rge
          raise NotFoundError unless RgeValidator.valid?(siret:, rge:)
        else
          raise NotFoundError unless RgeValidator.valid?(siret:)
        end

        render json: { siret:, rge:, valid: true }.compact
      end
    end
  end
end
