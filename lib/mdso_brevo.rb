# frozen_string_literal: true

require "brevo"
require "faraday"

# Interface between MDSO and Brevo
class MdsoBrevo # rubocop:disable Metrics/ClassLength
  attr_reader :email_params,
              :quotes_case,
              :quote_checks

  MAX_INBOUND_EMAILS_PER_DAY = 20

  def initialize(email_params)
    @email_params = email_params.to_unsafe_h
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

    webhook = brevo.webhooks_list.detect { it.fetch(:type) == "inbound" && it.fetch(:url) == url }
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

  # rubocop:disable Metrics/AbcSize
  def import_quote_check # rubocop:disable Metrics/MethodLength
    check_inbound_email_limit!

    return if manage_wrong_inbound_email

    if attachments.size > 1
      @quotes_case = QuotesCase.create!(
        profile:,
        renovation_type:,

        source_name:,

        email: from,
        email_to: to,
        email_subject: subject
      )
    end

    attachments.each { treat_attachment(it, no_email_response: quotes_case.present?) }

    QuotesCaseMailer.created_from_email(quotes_case).deliver_later if quotes_case

    quotes_case || quote_checks
    # rescue StandardError => e
    #   ErrorNotifier.notify(e, context: { email_params:, quotes_case_id: quotes_case&.id })
  end
  # rubocop:enable Metrics/AbcSize

  def profile
    # mail_alias = to.split("@").first
    # QuoteCheck::PROFILES.detect { mail_alias.match?(/#{it}/i) } ||
    @profile ||= "email"
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

  def check_inbound_email_limit!
    return if from&.match?(/@(?:beta)?\.gouv\.fr$/i) # No limit for government emails

    inbound_email_count_last_day = QuoteCheck.where(email: from)
                                             .where(created_at: (DateTime.now - 1.day)..)
                                             .count
    return unless inbound_email_count_last_day >= MAX_INBOUND_EMAILS_PER_DAY

    raise StandardError, "Inbound email limit exceeded for #{from}"
  end

  # Like in Api::V1::QuoteChecksController#create
  def create_quote_check(quote_check_args, no_email_response: false)
    quote_check_service = QuoteCheckService.new(*quote_check_args[0..3], **quote_check_args[4])
    quote_check = quote_check_service.quote_check

    QuoteCheckMailer.created_from_email(quote_check).deliver_later unless no_email_response

    QuoteFileSecurityScanJob.perform_later(quote_check.file.id)
    QuoteCheckCheckJob.perform_later(quote_check.id)

    QuoteCheckMailer.created(quote_check).deliver_later

    @quote_checks ||= []
    @quote_checks << quote_check

    quote_check
  end

  def subject
    email_params.fetch("Subject")
  end

  def to
    @to = email_params.fetch("Recipients").detect do |recipient|
      recipient.ends_with?("@#{ENV.fetch('INBOUND_MAIL_DOMAIN')}")
    end
  end

  # rubocop:disable Metrics/AbcSize
  def treat_attachment(attachment, no_email_response: false) # rubocop:disable Metrics/MethodLength
    filename = attachment.fetch("Name")
    content_type = attachment.fetch("ContentType")
    # attachment.fetch("ContentLength") # TODO: Check size limit?

    # Fetch attachment content from Brevo API synchronously
    # TODO: make async if performance issue
    tempfile = BrevoApi.new.download_inbound_email_attachment(
      attachment.fetch("DownloadToken")
    )

    quote_check_args = [
      tempfile, filename,
      quotes_case&.profile || profile,
      quotes_case&.renovation_type || renovation_type,
      {
        content_type:,
        case_id: quotes_case&.id,

        source_name:,

        email: from,
        to_email: to,
        email_subject: subject
      }
    ]
    create_quote_check(quote_check_args, no_email_response:)
  end
  # rubocop:enable Metrics/AbcSize

  # Forwarding wrong inbound emails to a fixed address
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  def manage_wrong_inbound_email # rubocop:disable Metrics/MethodLength
    return false if to && attachments.any?
    return unless inbound_forwarding_to

    # raise ActiveRecord::RecordNotFound, "No matching Inbound Email found"

    sender = email_params.fetch("From")
    original_to = email_params.fetch("Recipients")
    prefix_html = <<~HTML
      <p>Email de #{sender} reçu par #{original_to} avec #{attachments.size} pièce(s) jointe(s) :</p>
      <p>Ayant été envoyé à une mauvaise adresse ou sans pièce jointe, donc cet email n'a pas été traité.</p>
    HTML
    prefix_text = Html.html_to_text(prefix_html)

    stmp_params = {
      # email_params from https://developers.brevo.com/docs/inbound-parse-webhooks#parsed-email-payload
      # to https://github.com/getbrevo/brevo-ruby/blob/main/docs/SendSmtpEmail.md
      sender: { email: "devis@#{ENV.fetch('INBOUND_MAIL_DOMAIN')}" }, # TODO: re-use original_to if configured on Brevo
      to: inbound_forwarding_to,
      reply_to: email_params.fetch("ReplyTo") || sender,
      subject: "Fwd: #{subject}",
      htmlContent: "#{prefix_html}<br />#{email_params.fetch('RawHtmlBody')}",
      textContent: "#{prefix_text}\n\n#{email_params.fetch('RawTextBody')}",
      attachment: attachments.map do |attachment|
        tempfile = BrevoApi.new.download_inbound_email_attachment(attachment.fetch("DownloadToken"))
        Brevo::SendSmtpEmailAttachment.new(
          name: attachment.fetch("Name"),
          content: tempfile.base64_encoded
        )
      end.presence
    }.compact

    Brevo::TransactionalEmailsApi.new.send_transac_email(
      Brevo::SendSmtpEmail.new(stmp_params)
    )
  rescue Brevo::ApiError => e
    raise StandardError, (attachments.inspect + e.response_body) if e.respond_to?(:response_body)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def inbound_forwarding_to
    @inbound_forwarding_to ||= ENV.fetch("INBOUND_FORWARDING_MAIL", "").split(",").map do |email|
      { email: email.strip }
    end.presence
  end
end
