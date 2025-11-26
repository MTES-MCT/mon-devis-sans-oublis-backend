# frozen_string_literal: true

# This job checks if some QuoteChecks has timed out and processes it accordingly.
class QuoteChecksTimeoutJob < ScheduledCronJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :default

  CRONTAB = "*/5 * * * *"

  good_job_control_concurrency_with(total_limit: 1)

  def perform
    monitor_cron_job do
      quote_checks = QuoteCheck.pending.order(started_at: :asc)
      next unless quote_checks.any?

      quote_checks.each { QuoteCheckTimeout.new(it).check }
    end
  end
end
