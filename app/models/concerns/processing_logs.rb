# frozen_string_literal: true

# Add ProcessingLogs
module ProcessingLogs
  extend ActiveSupport::Concern

  included do
    has_many :processing_logs, dependent: :destroy, inverse_of: :processable
  end

  def start_processing_log(*tags, input_parameters: nil) # rubocop:disable Metrics/MethodLength
    tags = Array.wrap(tags).compact
    raise ArgumentError, "tags must be a String or Array of Strings" unless tags.any?

    processing_log = processing_logs.build(
      tags:,
      input_parameters:,
      started_at: Time.current
    )

    if block_given?
      begin
        yield_result = yield
        return yield_result
      ensure
        end_processing_log(processing_log)
      end
    end

    processing_log
  end

  def end_processing_log(processing_log, finished_at: Time.current)
    processing_log.finished_at = finished_at
    processing_log.save!

    processing_log
  end
end
