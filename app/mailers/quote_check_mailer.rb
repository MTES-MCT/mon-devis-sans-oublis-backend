# frozen_string_literal: true

# TODO: @@@ Fix from and reply to the original mail

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

  def created_from_email(quote_check, from: nil)
    @quote_check = quote_check

    mail(
      from: from || default_params[:from],
      to: quote_check.email,
      cci: admin_recipients,
      subject: subject("Devis en cours d'analyse")
    )
  end

  def results_available(quote_check, from: nil)
    @quote_check = quote_check

    mail(
      from: from || default_params[:from],
      to: quote_check.email,
      cci: admin_recipients,
      subject: subject("Devis analysé avec résultats disponibles")
    )
  end

  private

  def admin_recipients
    @admin_recipients ||= ENV["QUOTE_CHECK_EMAIL_RECIPIENTS"]&.strip&.split(",")
  end
end
