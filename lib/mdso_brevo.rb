# frozen_string_literal: true

require "faraday"

# Interface between MDSO and Brevo
class MdsoBrevo
  attr_reader :email_params,
              :quotes_case,
              :quote_checks

  def initialize(email_params)
    @email_params = email_params
  end

  # See documentation at https://developers.brevo.com/docs/inbound-parse-webhooks
  # Inbound will not appear in the Brevo dashboard https://app.brevo.com/app-store/webhooks
  # ...but present in the API
  def self.upsert_webhook! # rubocop:disable Metrics/MethodLength
    brevo = BrevoApi.new
    host = ENV.fetch("INBOUND_WEBHOOK_HOST", ENV.fetch("APPLICATION_HOST"))
    url = Rails.application.routes.url_helpers.from_brevo_email_api_v1_quote_checks_url(
      host:,
      protocol: "https"
    )

    webhook = brevo.webhooks_list.detect { it.fetch("type") == "inbound" && it.fetch("url") == url }
    webhook ||= brevo.webhook_create(
      type: "inbound",
      events: ["inboundEmailProcessed"],
      domain: ENV.fetch("INBOUND_MAIL_DOMAIN"),
      url:,
      auth: {
        type: "bearer",
        token: ENV.fetch("RAILS_INBOUND_EMAIL_PASSWORD")
      },
      description: "Webhook to receive QuoteCheck via inbound emails"
    )

    webhook
  end

  def from
    email_params.dig("From", "Address")
  end

  def import_quote_check # rubocop:disable Metrics/MethodLength
    raise ActiveRecord::RecordNotFound, "No matching Inbound Email found" unless to

    if attachments.size > 1
      @quotes_case = QuotesCase.create!(
        source_name:,
        email: from,
        profile:,
        renovation_type:
      )
    end

    attachments.each { treat_attachment(it) }

    quotes_case || quote_checks
    # rescue StandardError => e
    #   ErrorNotifier.notify(e, context: { email_params:, quotes_case_id: quotes_case&.id })
  end

  def profile
    @profile ||= begin
      mail_alias = to.split("@").first

      QuoteCheck::PROFILES.detect { mail_alias.match?(/#{it}/i) } ||
        "artisan"
    end
  end

  def renovation_type
    attachments.size > 1 ? "ampleur" : "geste"
  end

  def source_name
    "email"
  end

  private

  def attachments
    email_params.fetch("Attachments")
  end

  # Like in Api::V1::QuoteChecksController#create
  def create_quote_check(quote_check_args)
    quote_check_service = QuoteCheckService.new(*quote_check_args[0..3], **quote_check_args[4])
    quote_check = quote_check_service.quote_check

    QuoteCheckMailer.created_from_email(quote_check).deliver_later

    QuoteFileSecurityScanJob.perform_later(quote_check.file.id)
    QuoteCheckCheckJob.perform_later(quote_check.id)

    QuoteCheckMailer.created(quote_check).deliver_later

    @quote_checks ||= []
    @quote_checks << quote_check

    quote_check
  end

  def to
    @to = email_params.fetch("Recipients").detect do |recipient|
      recipient.ends_with?("@#{ENV.fetch('INBOUND_MAIL_DOMAIN')}")
    end
  end

  # rubocop:disable Metrics/AbcSize
  def treat_attachment(attachment) # rubocop:disable Metrics/MethodLength
    filename = attachment.fetch("Name")
    content_type = attachment.fetch("ContentType")
    # attachment.fetch("ContentLength") # TODO: Check size limit?

    # Fetch attachment content from Brevo API synchronously
    # TODO: make async if performance issue
    content = BrevoApi.new.download_inbound_email_attachment(
      attachment.fetch("DownloadToken")
    )
    tempfile = Tempfile.new(filename)
    tempfile.binmode
    tempfile.write(content)
    tempfile.rewind

    quote_check_args = [
      tempfile, filename,
      quotes_case&.profile || profile,
      quotes_case&.renovation_type || renovation_type,
      {
        content_type:,
        case_id: quotes_case&.id,
        source_name:,
        email: from
      }
    ]
    create_quote_check(quote_check_args)
  end
  # rubocop:enable Metrics/AbcSize
end
