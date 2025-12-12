# frozen_string_literal: true

# This class is responsible to compute stats
class StatsService
  def self.keys
    new.methods.sort - Object.methods - [:all]
  end

  def all
    {
      quote_checks_count:,
      average_quote_check_errors_count:,
      average_quote_check_processing_time:,
      average_quote_check_cost:,
      median_quote_check_processing_time:,
      unique_visitors_count:
    }
  end

  # rubocop:disable Metrics/AbcSize
  def quote_check_upload_funnel(date: "today", period: "day") # rubocop:disable Metrics/MethodLength
    funnel_paths = [
      "https://mon-devis-sans-oublis.beta.gouv.fr/",

      "/bienvenue",

      %w[
        /artisan/type-renovation
        /particulier/type-renovation
        /conseiller/type-renovation
      ],

      %w[
        /artisan/televersement/renovation-par-gestes
        /artisan/televersement/renovation-ampleur
        /conseiller/televersement/renovation-par-gestes
        /conseiller/televersement/renovation-ampleur
        /particulier/televersement/renovation-par-gestes
        /particulier/televersement/renovation-ampleur
      ]

      # TODO: during and after upload (same URL) like /artisan/dossier/[UUID]
    ]

    path_visits = funnel_paths.index_with do |path_or_paths|
      Array.wrap(path_or_paths).sum do |path|
        page_data = matomo_api.get_page_url(path, date:, period:).first
        page_data&.fetch("nb_visits").to_i # TODO: Use nb_hits instead?
      end
    end

    funnel_paths.each_with_index.map do |path, index|
      count = path_visits[path]

      previous_count = index.zero? ? count : path_visits[funnel_paths[index - 1]]
      conversion = previous_count.positive? ? (count.to_f / previous_count * 100).ceil(1) : 0.0

      { index: index + 1, path:, count:, conversion: }
    end
  end
  # rubocop:enable Metrics/AbcSize

  protected

  def average_quote_check_cost
    quote_checks_with_qa = QuoteCheck.where.not(qa_result: nil)
    return nil if quote_checks_with_qa.none?

    costs = quote_checks_with_qa.select(:qa_result).flat_map(&:cost).compact
    (costs.sum.to_f / costs.size).ceil(2) if costs.any?
  end

  def average_quote_check_errors_count
    return nil if QuoteCheck.none?

    total_errors_count = QuoteCheck.where.not(validation_errors: nil).pluck(:validation_errors).sum(&:size)
    (total_errors_count.to_f / QuoteCheck.count).ceil(1)
  end

  # In seconds
  def average_quote_check_processing_time
    quote_checks_finished = QuoteCheck.with_valid_processing_time
    return nil if quote_checks_finished.none?

    total_processing_time = quote_checks_finished.select(:finished_at, :started_at).sum(&:processing_time)
    (total_processing_time.to_f / quote_checks_finished.count).ceil
  end

  # In seconds
  def median_quote_check_processing_time
    quote_checks_finished = QuoteCheck.with_valid_processing_time
    return nil if quote_checks_finished.none?

    processing_times = quote_checks_finished.select(:finished_at, :started_at).map { it.processing_time.ceil }
    median(processing_times)
  end

  def quote_checks_count
    QuoteCheck.count
  end

  def unique_visitors_count
    matomo_api.value(method: "VisitsSummary.getUniqueVisitors") if MatomoApi.auto_configured?
  rescue MatomoApi::TimeoutError
    nil
  end

  private

  def matomo_api
    @matomo_api ||= MatomoApi.new
  end

  def median(array)
    return nil if array.empty?

    sorted = array.sort
    mid = sorted.length / 2

    if sorted.length.odd?
      sorted[mid] # Odd-length array → middle element
    else
      (sorted[mid - 1] + sorted[mid]) / 2.0 # Even-length array → average of two middle elements
    end
  end
end
