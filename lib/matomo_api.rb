# frozen_string_literal: true

require "net/http"

# See https://developer.matomo.org/api-reference/reporting-api#standard-api-parameters
class MatomoApi
  class ResultError < StandardError; end
  class TimeoutError < ResultError; end

  def initialize(domain: nil, id_site: nil, token_auth: nil)
    @domain = domain || ENV.fetch("MATOMO_DOMAIN", "stats.beta.gouv.fr")
    @token_auth = token_auth || ENV.fetch("MATOMO_TOKEN_AUTH")
    @id_site = id_site || ENV.fetch("MATOMO_SITE_ID")
  end

  def self.auto_configured?
    ENV.key?("MATOMO_TOKEN_AUTH")
  end

  # rubocop:disable Metrics/MethodLength
  def value(method: "VisitsSummary.getUniqueVisitors", period: "range", date: nil)
    date ||= "2011-01-01,#{1.day.from_now.strftime('%Y-%m-%d')}"

    response = Net::HTTP.post_form(URI("https://#{@domain}/index.php"), {
                                     module: "API",
                                     format: "JSON",
                                     idSite: @id_site,
                                     method:,
                                     period:,
                                     date:,
                                     token_auth: @token_auth
                                   })

    json = JSON.parse(response.body)
    json.fetch("value")
  rescue Net::ReadTimeout => e
    raise TimeoutError, e
  end
  # rubocop:enable Metrics/MethodLength
end
