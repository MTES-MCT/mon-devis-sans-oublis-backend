# frozen_string_literal: true

module Api
  module V1
    # Module to manage API access
    module ApiAccess
      extend ActiveSupport::Concern

      ENV_API_KET_PREFIX = "MDSO_API_KEY_FOR_"

      def self.api_keys
        env_keys.to_h do |env_key|
          [
            env_key.remove(ENV_API_KET_PREFIX),
            ENV.fetch(env_key).gsub(/.(?=.{4})/, "*")
          ]
        end
      end

      def self.env_keys
        ENV.keys.select { it.start_with?(ENV_API_KET_PREFIX) }
      end

      protected

      def api_key
        auth = request.headers["Authorization"].to_s
        auth.remove("Bearer ").strip
      end

      def api_user
        Api::V1::ApiAccess.env_keys.detect { api_key == ENV.fetch(it) }&.remove(ENV_API_KET_PREFIX) if api_key
      end

      def api_user_mdso?
        api_user.present? && api_user.downcase == "mdso"
      end
    end
  end
end
