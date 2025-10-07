# frozen_string_literal: true

require "net/http"

require "faraday"

# See https://developer.matomo.org/api-reference/reporting-api#standard-api-parameters
class MatomoApi
  class ResultError < StandardError; end
  class TimeoutError < ResultError; end

  attr_reader :domain, :id_site

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

    path_params = {
      module: "API",
      format: "JSON",
      idSite: id_site,
      method:,
      date:,
      period:
    }
    uri = "#{base_url}?#{URI.encode_www_form(path_params)}"
    response = wrap_timeout { connection.post(uri, token_auth: @token_auth) }

    json = parse_response(response)
    json.fetch("value")
  end

  # rubocop:enable Metrics/MethodLength
  def get_page_url(page_url, date: "today", period: "day") # rubocop:disable Metrics/MethodLength
    path_params = {
      module: "API",
      format: "JSON",
      idSite: id_site,
      method: "Actions.getPageUrl",
      pageUrl: page_url,
      date: date,
      period: period
    }

    uri = "#{base_url}?#{URI.encode_www_form(path_params)}"
    response = connection.post(uri, token_auth: @token_auth)

    parse_response(response)
  end

  def get_page_urls(date: "today", period: "day") # rubocop:disable Metrics/MethodLength
    path_params = {
      module: "API",
      format: "JSON",
      idSite: id_site,
      method: "Actions.getPageUrls",
      date: date,
      period: period
    }

    uri = "#{base_url}?#{URI.encode_www_form(path_params)}"
    response = connection.post(uri, token_auth: @token_auth)

    parse_response(response)
  end

  private

  def base_url
    "https://#{@domain}/index.php"
  end

  def connection
    @connection ||= Faraday.new(url: base_url) do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter

      f.ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def parse_response(response)
    json = JSON.parse(response.body) if response.success?
    if json.nil? ||
       (json.is_a?(Hash) && json["result"] == "error")
      raise ResultError, "HTTP #{response.status} #{response.body}"
    end

    json
  end

  def wrap_timeout
    yield
  rescue Faraday::TimeoutError,
         Faraday::ConnectionFailed,
         Net::ReadTimeout => e
    raise TimeoutError, e.message
  end
end
