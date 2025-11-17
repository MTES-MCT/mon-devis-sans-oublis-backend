# frozen_string_literal: true

require "brevo"

# Interface with Brevo API
class BrevoApi
  HOST = "https://api.brevo.com/v3"

  def initialize(api_key: ENV.fetch("BREVO_API_KEY"))
    @api_key = api_key
  end

  def self.auto_configured?
    ENV.key?("BREVO_API_KEY")
  end

  def webhook_create(params)
    api_instance(Brevo::WebhooksApi).create_webhook(params)
  end

  def webhook_delete(webhook_id)
    api_instance(Brevo::WebhooksApi).delete_webhook(webhook_id)
  end

  def webhooks_list
    api_instance(Brevo::WebhooksApi).get_webhooks.webhooks
  end

  def download_inbound_email_attachment(download_token)
    api_instance(Brevo::InboundParsingApi).get_inbound_email_attachment(download_token)
  end

  private

  def api_instance(klass = Brevo::InboundParsingApi)
    klass.new.tap do |api_instance|
      api_instance.api_client.config.api_key["api-key"] = @api_key
    end
  end
end
