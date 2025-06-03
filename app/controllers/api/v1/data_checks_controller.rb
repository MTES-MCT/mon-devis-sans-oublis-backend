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
          date = params[:date]
          siret = SiretValidator.validate_format!(params[:siret])
          rge = RgeValidator.validate_format!(params[:rge]) if params[:rge].present?
          results = nil

          results = if rge
                      RgeValidator.valid?(date:, siret:, rge:)
                    else
                      RgeValidator.valid?(date:, siret:)
                    end
          raise NotFoundError.new(nil, validator_error_code: "rge_manquant") unless results
        rescue QuoteValidator::Base::ArgumentError => e
          raise BadRequestError.new(e.message, validator_error_code: e.error_code)
        end

        render json: { results:, valid: true }.compact
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
