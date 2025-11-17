# frozen_string_literal: true

if ENV.key?("BREVO_API_KEY")
  require "brevo"

  ActiveSupport.on_load(:action_mailer) do
    # rubocop:disable Lint/ConstantDefinitionInBlock
    module Brevo
      class SMTP < ::Mail::SMTP; end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    ActionMailer::Base.add_delivery_method :brevo, Brevo::SMTP
    ActionMailer::Base.brevo_settings = {
      user_name: ENV.fetch("BREVO_SMTP_USER_NAME"),
      password: ENV.fetch("BREVO_SMTP_USER_PASSWORD"),
      address: ENV.fetch("BREVO_SMTP_ADDRESS", "smtp-relay.brevo.com"),
      port: Integer(ENV.fetch("BREVO_SMTP_PORT", "587")),
      autentication: :plain,
      enable_starttls_auto: true,
      domain: Rails.application.config.action_mailer.default_url_options[:host]
    }
  end

  Brevo.configure do |config|
    config.api_key["api-key"] = ENV.fetch("BREVO_API_KEY")
  end

  Rails.application.config.action_mailer.delivery_method = :brevo unless Rails.env.test?
end
