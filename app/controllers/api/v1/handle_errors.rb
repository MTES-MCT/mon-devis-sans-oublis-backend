# frozen_string_literal: true

module Api
  module V1
    # Module to handle and format exceptions automatically
    module HandleErrors
      extend ActiveSupport::Concern

      class BadRequestError < StandardError; end
      class NotFoundError < StandardError; end
      class UnauthorizedError < StandardError; end

      included do
        rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
        rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
        rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

        rescue_from BadRequestError, with: :handle_bad_request
        rescue_from NotFoundError, with: :handle_record_not_found
        rescue_from UnauthorizedError, with: :handle_unauthorized
      end

      private

      def api_error(error, message = nil, status = :bad_request)
        render json: {
          error: error,
          message: Array.wrap(message).presence
        }.compact, status: status
      end

      def handle_bad_request(exception)
        api_error("Bad request", exception.message, :bad_request)
      end

      def handle_parameter_missing(exception)
        api_error("Parameter missing", exception.message, :bad_request)
      end

      def handle_record_invalid(exception)
        api_error("Validation failed", exception.record.errors.full_messages, :unprocessable_entity)
      end

      def handle_record_not_found(exception)
        api_error("Record not found", exception.message, :not_found)
      end

      def handle_unauthorized(exception = nil)
        api_error("Unauthorized", exception&.message || "HTTP Basic: Access denied.", :unauthorized)
      end
    end
  end
end
