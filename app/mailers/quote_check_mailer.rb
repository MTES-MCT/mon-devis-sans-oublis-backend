# frozen_string_literal: true

require "nokogiri"

class QuoteCheckMailer < ApplicationMailer
  def created(quote_check)
    @quote_check = quote_check

    return if admin_recipients.blank?

    mail(
      to: admin_recipients.first,
      cc: admin_recipients[1..],
      subject: subject("Nouveau devis soumis #{quote_check.id}")
    )
  end

  def created_from_email(quote_check)
    @quote_check = quote_check

    mail(
      from: quote_check.email_to || default_params[:from],
      to: quote_check.email,
      subject: (quote_check.email_subject && "Re: #{quote_check.email_subject}") ||
               self.subject("Devis en cours d'analyse"),
      bcc: admin_recipients
    )
  end

  def results_available(quote_check) # rubocop:disable Metrics/MethodLength
    @quote_check = quote_check

    @content_html = QuoteErrorEmailGenerator.generate_email_content(quote_check)
    @content_text = Nokogiri::HTML(@content_html).text

    mail(
      from: quote_check.email_to || default_params[:from],
      to: quote_check.email,
      subject: (quote_check.email_subject && "Re: #{quote_check.email_subject}") ||
               self.subject("Devis analysé avec résultats disponibles"),
      bcc: admin_recipients
    )
  end
end
