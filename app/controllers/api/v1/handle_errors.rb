# frozen_string_literal: true

module Api
  module V1
    # Module to handle and format exceptions automatically
    module HandleErrors
      extend ActiveSupport::Concern

      class ApiError < StandardError; end

      # Custom error class for API errors with a message and optional validator error code
      class ApiErrorWithCode < ApiError
        attr_reader :error_code, :validator_error_code

        def initialize(message = nil, validator_error_code: nil)
          if validator_error_code
            message ||= I18n.t("quote_validator.errors.#{validator_error_code}", default: nil)&.strip
          end

          super(message)

          @validator_error_code = validator_error_code
          @error_code = validator_error_code
        end
      end

      class BadRequestError < ApiErrorWithCode; end
      class NotFoundError < ApiErrorWithCode; end
      class UnauthorizedError < ApiError; end
      class UnprocessableEntityError < ApiErrorWithCode; end

      included do
        rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
        rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
        rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

        rescue_from BadRequestError, with: :handle_bad_request
        rescue_from NotFoundError, with: :handle_record_not_found
        rescue_from UnauthorizedError, with: :handle_unauthorized
        rescue_from UnprocessableEntityError, with: :handle_unprocessable_entity
      end

      private

      # @param error [Exception, String]
      # @param message [String]
      # @param status [Symbol, String, Number]
      def api_error(error, message = nil, status = :bad_request) # rubocop:disable Metrics/MethodLength
        # Format specific Validator error like data checks

        error_json = if error.is_a?(ApiErrorWithCode) && error.validator_error_code
                       {
                         error_details: [{
                           code: error.validator_error_code
                         }],
                         valid: false
                       }
                     else
                       {
                         error: error,
                         message: Array.wrap(message).presence
                       }
                     end

        render json: error_json.compact, status: status
      end

      def handle_bad_request(exception)
        error = exception.is_a?(ApiErrorWithCode) ? exception : "Bad request"
        api_error(error, exception.message, :bad_request)
      end

      def handle_parameter_missing(exception)
        error = exception.is_a?(ApiErrorWithCode) ? exception : "Parameter missing"
        api_error(error, exception.message, :bad_request)
      end

      def handle_record_invalid(exception)
        error = exception.is_a?(ApiErrorWithCode) ? exception : "Validation failed"
        api_error(error, exception.record.errors.full_messages, :unprocessable_entity)
      end

      def handle_record_not_found(exception)
        error = exception.is_a?(ApiErrorWithCode) ? exception : "Record not found"
        api_error(error, exception.message, :not_found)
      end

      def handle_unauthorized(exception = nil)
        error = exception.is_a?(ApiErrorWithCode) ? exception : "Unauthorized"
        api_error(error, exception&.message || "HTTP Basic: Access denied.", :unauthorized)
      end

      def handle_unprocessable_entity(exception = nil)
        error = exception.is_a?(ApiErrorWithCode) ? exception : "Unprocessable entity"
        api_error(error, exception&.message || "Unprocessable entity.", :unprocessable_entity)
      end
    end
  end
end
