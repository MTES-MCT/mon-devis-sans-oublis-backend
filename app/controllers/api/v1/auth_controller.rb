# frozen_string_literal: true

module Api
  module V1
    # Controller to handle API key authentication
    class AuthController < BaseController
      def check
        raise UnauthorizedError, "API key is required or invalid" unless api_user

        render json: { user: api_user }
      end
    end
  end
end
