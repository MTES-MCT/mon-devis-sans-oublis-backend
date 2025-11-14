# frozen_string_literal: true

require "nokogiri"

class QuotesCaseMailer < ApplicationMailer
  def created_from_email(quotes_case)
    @quotes_case = quotes_case

    mail(
      from: quotes_case.email_to || default_params[:from],
      to: quotes_case.email,
      subject: (quotes_case.email_subject && "Re: #{quotes_case.email_subject}") ||
               subject("Dossier en cours d'analyse"),
      bcc: admin_recipients
    )
  end

  def results_available(quotes_case) # rubocop:disable Metrics/MethodLength
    @quotes_case = quotes_case

    content_generator = QuoteErrorEmailGenerator.new(quotes_case)
    @content_html = content_generator.html
    @content_text = content_generator.text
    @link = @quotes_case.frontend_webapp_url(mtm_campaign: "full_email")

    mail(
      from: quotes_case.email_to || default_params[:from],
      to: quotes_case.email,
      subject: (quotes_case.email_subject && "Re: #{quotes_case.email_subject}") ||
               subject("Dossier analysé avec résultats disponibles"),
      bcc: admin_recipients
    )
  end
end
