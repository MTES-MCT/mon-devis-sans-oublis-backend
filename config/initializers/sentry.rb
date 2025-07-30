# frozen_string_literal: true

if defined?(Sentry)
  Sentry.init do |config|
    config.dsn = ENV.fetch("SENTRY_DSN")
    config.breadcrumbs_logger = %i[active_support_logger http_logger]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 0.5

    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.application.config.app_env)
    config.release = ENV.fetch("CONTAINER_VERSION", `git rev-parse HEAD`).strip
  end
end
