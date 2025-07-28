# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class DataChecksController < BaseController
      def geste_types # rubocop:disable Metrics/MethodLength
        geste_types = QuoteCheck::GESTE_TYPES
        render json: {
          data: geste_types,
          options: QuoteCheck::GESTE_TYPES_GROUPS.flat_map do |group, geste_types|
            geste_types.map do |geste_type|
              {
                group: group,
                label: I18n.t("quote_checks.geste_type.title.#{geste_type}"),
                value: geste_type
              }
            end
          end
        }
      end

      # rubocop:disable Metrics/AbcSize
      def rge # rubocop:disable Metrics/MethodLength
        started_at = Time.current
        source = detect_request_source
        
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
          
          log_rge_request(params, { results:, valid: true }, source, started_at, success: true)
          
        rescue QuoteValidator::Base::ArgumentError => e
          log_rge_request(params, { error: e.message, error_code: e.error_code }, source, started_at, success: false)
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

      private

      def detect_request_source
        request.headers['User-Agent'].to_s
      end

      def log_rge_request(params, result, source, started_at, success:)
        ProcessingLog.create!(
          processable_type: 'RgeCheck',
          tags: ['rge_validation', success ? 'success' : 'error'].compact,
          input_parameters: {
            siret: params[:siret],
            rge: params[:rge],
            date: params[:date],
            geste_types: params[:geste_types],
            user_agent: request.headers['User-Agent'],
            referer: request.headers['Referer'],
          },
          output_result: result,
          started_at: started_at,
          finished_at: Time.current
        )
      rescue Stand