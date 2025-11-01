# frozen_string_literal: true

require "faraday"

# Interface with Brevo API
class BrevoApi
  HOST = "https://api.brevo.com/v3"

  class BadRequestError < StandardError; end

  def initialize(api_key: ENV.fetch("BREVO_API_KEY"))
    @api_key = api_key
  end

  def self.auto_configured?
    ENV.key?("BREVO_API_KEY")
  end

  def webhook_create(params)
    body = connection.post("webhooks", params).body

    raise BadRequestError, body if body.key?("code") && body["code"] == "invalid_parameter"

    body
  end

  def webhook_delete(webhook_id)
    path = "webhooks/#{Faraday::Utils.escape(webhook_id)}"
    connection.delete(path).body
  end

  def webhooks_list
    parse_result_list(connection.get("webhooks").body, "webhooks")
  end

  def download_inbound_email_attachment(download_token)
    response = connection.get("inbound/attachments/#{download_token}",
                              headers: { "Accept" => "application/octet-stream" })
    raise BadRequestError, response.body if response.status == 400

    response.body
  end

  private

  def connection # rubocop:disable Metrics/MethodLength
    @connection ||= Faraday.new(
      url: HOST,
      headers: {
        "api-key" => @api_key,
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    ) do |f|
      f.request :json
      f.response :json
    end
  end

  def parse_result_list(json, key)
    return [] if json.key?("code") && json["code"] == "document_not_found"

    raise BadRequestError, json unless json.key?(key)

    json.fetch(key)
  end
end
