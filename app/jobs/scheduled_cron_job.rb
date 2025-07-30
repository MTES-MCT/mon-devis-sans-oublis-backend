# frozen_string_literal: true

# Base class for scheduled cron jobs with Sentry monitoring
class ScheduledCronJob < ApplicationJob
  protected

  def monitor_cron_job
    crontab = Rails.application.config.good_job.dig(:cron, name.underscore.to_sym, :cron) || raise(NotImplementedError)

    monitor_config = Sentry::Cron::MonitorConfig.from_crontab(crontab)
    monitor_slug = self.class.name

    check_in_id = Sentry.capture_check_in(
      monitor_slug, :in_progress, monitor_config:
    )

    yield

    Sentry.capture_check_in(
      monitor_slug, :ok, check_in_id:, monitor_config:
    )
  end
end
