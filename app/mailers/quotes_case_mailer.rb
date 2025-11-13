# frozen_string_literal: true

require "nokogiri"

class QuotesCaseMailer < ApplicationMailer
  def created_from_email(quotes_case)
    @quotes_case = quotes_case

    mail(
      from: quotes_case.email_to || default_params[:from],
      to: quotes_case.email,
      subject: (quotes_case.email_subject && "Re: #{quotes_case.email_subject}") ||
               self.subject("Dossier en cours d'analyse"),
      bcc: admin_recipients
    )
  end

  # rubocop:disable Metrics/AbcSize
  def results_available(quotes_case) # rubocop:disable Metrics/MethodLength
    @quotes_case = quotes_case

    @content_html = QuoteErrorEmailGenerator.generate_case_email_content(quotes_case)
    @content_text = Nokogiri::HTML(@content_html).text

    mail(
      from: quotes_case.email_to || default_params[:from],
      to: quotes_case.email,
      subject: (quotes_case.email_subject && "Re: #{quotes_case.email_subject}") ||
               self.subject("Dossier analysé avec résultats disponibles"),
      bcc: admin_recipients
    )
  end
  # rubocop:enable Metrics/AbcSize
end
