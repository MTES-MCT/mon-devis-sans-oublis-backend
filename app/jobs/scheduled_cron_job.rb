# frozen_string_literal: true

# Base class for scheduled cron jobs with Sentry monitoring
class ScheduledCronJob < ApplicationJob
  protected

  # rubocop:disable Metrics/AbcSize
  def monitor_cron_job # rubocop:disable Metrics/MethodLength
    return yield unless defined?(Sentry)

    crontab = Rails.application.config.good_job.dig(:cron, self.class.name.underscore.to_sym, :cron) ||
              raise(NotImplementedError)
    monitor_config = Sentry::Cron::MonitorConfig.from_crontab(crontab)
    monitor_slug = self.class.name

    check_in_id = Sentry.capture_check_in(monitor_slug, :in_progress, monitor_config:)

    yield

    Sentry.capture_check_in(monitor_slug, :ok, check_in_id:, monitor_config:)
  rescue => e # rubocop:disable Style/RescueStandardError
    Sentry.capture_check_in(monitor_slug, :error, check_in_id:, monitor_config:)
    raise e
  end
  # rubocop:enable Metrics/AbcSize
end
