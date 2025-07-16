# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class DataChecksController < BaseController
      def geste_types
        render json: { data: QuoteCheck::GESTE_TYPES }
      end

      # rubocop:disable Metrics/AbcSize
      def rge # rubocop:disable Metrics/MethodLength
        begin
          date = params[:date]
          siret = SiretValidator.validate_format!(params[:siret])
          rge = RgeValidator.validate_format!(params[:rge]) if params[:rge].present?
          geste_types = Array.wrap((params[:geste_types].presence || "").split(","))

          results = nil

          if geste_types.any? { QuoteCheck::GESTE_TYPES.exclude?(it) }
            raise UnprocessableEntityError.new(nil, validator_error_code: "geste_type_inconnu")
          end

          results = if rge
                      RgeValidator.valid?(date:, siret:, rge:, geste_types:)
                    else
                      RgeValidator.valid?(date:, siret:, geste_types:)
                    end
          raise NotFoundError.new(nil, validator_error_code: "rge_manquant") unless results
        rescue QuoteValidator::Base::ArgumentError => e
          raise BadRequestError.new(e.message, validator_error_code: e.error_code)
        end

        render json: { results:, valid: true }.compact
      end
      # rubocop:enable Metrics/AbcSize

      def siret
        siret = params[:siret]

        begin
          raise NotFoundError.new(nil, validator_error_code: "siret_manquant") unless SiretValidator.valid?(siret)
        rescue QuoteValidator::Base::ArgumentError => e
          raise BadRequestError.new(e.message, validator_error_code: e.error_code)
        end

        render json: { valid: true }
      end
    end
  end
end
