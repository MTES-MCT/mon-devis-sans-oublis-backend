# frozen_string_literal: true

# Notifies Sentry of errors
class ErrorNotifier
  def self.notify(error)
    set_context(:application, { version: Rails.application.config.application_version })
    Sentry.capture_exception(error) if defined?(Sentry)
    Rails.logger.error(error)
  end

  def self.set_context(name, attributes)
    return unless defined?(Sentry)

    Sentry.configure_scope do |scope|
      scope.set_context(name, attributes)
    end
  end
end
