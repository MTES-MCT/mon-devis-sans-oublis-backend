# frozen_string_literal: true

# Job to validate a QuoteCheck against the RNT (Référentiel National des Travaux)
class QuoteCheckRntValidateJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :rnt_checks

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "#{self.class.name}-#{queue_name}-#{arguments.first}" }
  )
  retry_on Llms::Albert::TooManyRequestsError, wait: 1.minute

  def perform(quote_check_id)
    return unless QuoteCheck.exists?(quote_check_id)

    RntValidatorService.new(quote_check_id).validate

  # Manage Albert usage limits:
  # 128000 input tokens albert-large / minute
  # 2460000 input tokens albert-large / day
  rescue Llms::Albert::TooManyRequestsError => e
    ErrorNotifier.set_context(:quote_check, { id: quote_check_id })
    ErrorNotifier.notify(e)
    raise e
  end
end
