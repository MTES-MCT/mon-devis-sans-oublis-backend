# frozen_string_literal: true

module Api
  module V1
    # Controller to handle inbound Brevo webhooks for email parsing
    class BrevoWebhooksController < BaseController
      # protect_from_forgery with: :null_session
      before_action :authenticate_relay

      def inbound_emails
        # TODO: use Rails Action Mailbox with a Brevo adapter instead
        params[:items]&.each { MdsoBrevo.new(it).import_quote_check }

        head :ok
      end

      private

      def authenticate_relay
        return if authenticated?

        Rails.logger.warn("Unauthorized Brevo webhook attempt")
        head :unauthorized
      end

      def authenticated?
        extract_token_from_request.present? &&
          ActiveSupport::SecurityUtils.secure_compare(
            extract_token_from_request,
            ENV.fetch("RAILS_INBOUND_EMAIL_PASSWORD")
            # TODO: Rails.application.credentials.action_mailbox.ingress_password
          )
      end

      def extract_token_from_request
        authorization_header = request.headers["Authorization"]
        authorization_header&.gsub(/^Bearer /i, "")
      end
    end
  end
end
