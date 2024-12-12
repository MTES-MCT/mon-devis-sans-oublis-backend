# frozen_string_literal: true

module Api
  module V1
    # Module to handle and format exceptions automatically
    module HandleErrors
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
        rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
        rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
      end

      private

      def api_error(error, message, status)
        render json: {
          error: error,
          message: message
        }, status: status
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
    end
  end
end
