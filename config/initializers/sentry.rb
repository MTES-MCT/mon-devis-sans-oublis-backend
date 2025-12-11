# frozen_string_literal: true

if defined?(Sentry)
  require "brevo"

  Sentry.init do |config|
    config.dsn = ENV.fetch("SENTRY_DSN")
    config.breadcrumbs_logger = %i[active_support_logger http_logger]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 0.5

    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.application.config.app_env)
    config.release = ENV.fetch("CONTAINER_VERSION", `git rev-parse HEAD`).strip


    if ActiveModel::Type::Boolean.new.cast(ENV.fetch("SENTRY_LOGS_ENABLED", "false"))
      config.enable_logs = true
      config.enabled_patches = [:logger] # :puma, :faraday, :redis
    end

    config.before_send = lambda do |event, hint|
      err = hint[:exception]

      # Customize event based on exception type
      case err
      when Brevo::ApiError
        event.extra ||= {}
        event.extra[:code] ||= err.code
        event.extra[:response_body] ||= err.response_body
        event.extra[:response_headers] ||= err.response_headers
      when MdsoApi::InvalidResponse
        event.priority = "low"
      end

      event
    end
  end
end
