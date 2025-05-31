# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class DataChecksController < BaseController
      def siret
        siret = params[:siret]

        begin
          raise NotFoundError.new(nil, validator_error_code: "siret_manquant") unless SiretValidator.valid?(siret)
        rescue QuoteValidator::Base::ArgumentError => e
          raise BadRequestError.new(e.message, validator_error_code: e.error_code)
        end

        render json: { valid: true }
      end

      # rubocop:disable Metrics/AbcSize
      def rge # rubocop:disable Metrics/MethodLength
        begin
          siret = SiretValidator.validate_format!(params[:siret])
          rge = RgeValidator.validate_format!(params[:rge]) if params[:rge].present?

          if rge
            raise NotFoundError.new(nil, validator_error_code: "rge_manquant") unless RgeValidator.valid?(siret:, rge:)
          else
            raise NotFoundError.new(nil, validator_error_code: "rge_manquant") unless RgeValidator.valid?(siret:)
          end
        rescue QuoteValidator::Base::ArgumentError => e
          raise BadRequestError.new(e.message, validator_error_code: e.error_code)
        end

        render json: { valid: true }.compact
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
