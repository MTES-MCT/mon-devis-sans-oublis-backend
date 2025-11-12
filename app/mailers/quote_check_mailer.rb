# frozen_string_literal: true

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

  def created_from_email(quote_check, from: nil, subject: nil)
    @quote_check = quote_check

    mail(
      from: from || quote_check.email_to || default_params[:from],
      to: quote_check.email,
      subject: subject ||
               (quote_check.email_subject && "Re: #{quote_check.email_subject}") ||
               self.subject("Devis en cours d'analyse"),
      bcc: admin_recipients
    )
  end

  def results_available(quote_check, from: nil, subject: nil)
    @quote_check = quote_check

    mail(
      from: from || quote_check.email_to || default_params[:from],
      to: quote_check.email,
      subject: subject ||
               (quote_check.email_subject && "Re: #{quote_check.email_subject}") ||
               self.subject("Devis analysé avec résultats disponibles"),
      bcc: admin_recipients
    )
  end

  private

  def admin_recipients
    @admin_recipients ||= ENV["QUOTE_CHECK_EMAIL_RECIPIENTS"]&.strip&.split(",")
  end
end
