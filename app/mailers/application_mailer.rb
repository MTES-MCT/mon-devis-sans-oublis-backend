# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_EMAIL_FROM", "from@example.com")
  layout "mailer"

  def subject(text)
    subject_parts = ["[#{Rails.application.config.application_name}]"]

    specific_env = ([Rails.application.config.app_env, Rails.env] - ["production"]).first
    subject_parts << "[#{specific_env}]" if specific_env

    subject_parts << text

    subject_parts.join(" ")
  end

  protected

  def admin_recipients
    @admin_recipients ||= ENV["QUOTE_CHECK_EMAIL_RECIPIENTS"]&.strip&.split(",")
  end
end
