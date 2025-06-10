# frozen_string_literal: true

module ActiveAdmin
  # Specialized view helpers for ActiveAdmin
  module ViewHelpers
    def geste_errors(quote_check, geste_index)
      geste_id = QuoteValidator::Base.geste_index(
        quote_check.id, geste_index
      )
      quote_check.validation_error_details&.select { |error| error["geste_id"] == geste_id }
    end

    def local_time(time, with_seconds: false)
      time_format = with_seconds ? "%d/%m/%Y %H:%M:%S" : "%d/%m/%Y %H:%M"
      time&.in_time_zone("Europe/Paris")&.strftime(time_format)
    end

    # Call via "instance_exec(&processing_logs_tab(resource))"
    # rubocop:disable Metrics/AbcSize
    def processing_logs_tab(resource) # rubocop:disable Metrics/MethodLength
      return -> {} if resource.processing_logs.none?

      proc do
        # ::ActiveAdmin::Views::TabsRenderer.new(self).instance_eval do
        tab "Logs de traitement" do
          table_for resource.processing_logs.order(finished_at: :desc) do
            column :tags
            column :started_at do
              local_time(it.started_at, with_seconds: true)
            end
            column :finished_at do
              local_time(it.finished_at, with_seconds: true)
            end
            column "Durée (s)", :duration
            column :input_parameters do
              pre JSON.pretty_generate(it.input_parameters) if it.input_parameters.present?
            end
            column :output_result do
              pre JSON.pretty_generate(it.output_result) if it.output_result.present?
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
