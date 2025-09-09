# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class DataChecksController < BaseController
      def geste_types # rubocop:disable Metrics/MethodLength
        geste_types = GesteTypes::VALUES
        render json: {
          data: geste_types,
          options: GesteTypes::GROUPS.flat_map do |group, geste_types|
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
        request_params = extract_rge_params

        results = nil
        begin
          results = RgeValidator.valid?(
            date: request_params[:date],
            siret: request_params[:siret],
            rge: request_params[:rge],
            geste_types: request_params[:geste_types]
          )
        rescue QuoteValidator::Base::ArgumentError => e
          log_rge_request(request_params, { error: e.message, error_code: e.error_code }, source, started_at,
                          success: false)
          case e.error_code
          when "geste_type_inconnu"
            raise UnprocessableEntityError.new(e.message, validator_error_code: e.error_code)
          else
            raise BadRequestError.new(e.message, validator_error_code: e.error_code)
          end
        end

        valid = results.present? && results.any?
        unless valid
          log_rge_request(request_params, { error_code: "rge_manquant" }, source, started_at, success: false)
          raise NotFoundError.new(nil, validator_error_code: "rge_manquant")
        end

        log_rge_request(request_params, { results:, valid: }, source, started_at, success: true)
        render json: { results:, valid: }.compact
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
        api_user || request.headers["User-Agent"]&.to_s
      end

      def extract_rge_params # rubocop:disable Metrics/AbcSize
        {
          date: params[:date],
          siret: params[:siret].present? ? SiretValidator.validate_format!(params[:siret]) : nil,
          rge: params[:rge].present? ? RgeValidator.validate_format!(params[:rge]) : nil,
          geste_types: Array.wrap((params[:geste_types].presence || "").split(","))
        }
      rescue QuoteValidator::Base::ArgumentError => e
        raise BadRequestError.new(e.message, validator_error_code: e.error_code)
      end

      def log_rge_request(request_params, result, _source, started_at, success:)
        ProcessingLog.create!(log_attributes(request_params, result, started_at, success))
      rescue StandardError => e
        Rails.logger.error "Failed to log RGE request: #{e.message}"
      end

      def log_attributes(request_params, result, started_at, success)
        {
          processable_type: nil,
          processable_id: nil,
          tags: ["rge_validation", success ? "success" : "error"].compact,
          input_parameters: log_input_parameters(request_params),
          output_result: result,
          started_at: started_at,
          finished_at: Time.current
        }
      end

      def log_input_parameters(request_params)
        {
          siret: request_params[:siret],
          rge: request_params[:rge],
          date: request_params[:date],
          geste_types: request_params[:geste_types],
          user_agent: request.headers["User-Agent"],
          referer: request.headers["Referer"]
        }
      end
    end
  end
end
