# frozen_string_literal: true

module Api
  module V1
    # Base controller for API V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Basic::ControllerMethods

      include Api::V1::ApiAccess
      include Api::V1::HandleErrors

      protected

      def authorize_request
        return true if api_user

        # Old DEPRECATED way
        authenticate_with_http_basic do |username, password|
          if username == "mdso" &&
             password == ENV.fetch("MDSO_API_PASSWORD") { ENV.fetch("MDSO_SITE_PASSWORD") }
            return true
          end
        end

        handle_unauthorized
      end
    end
  end
end
