# frozen_string_literal: true

# Mail previews for QuoteCheckMailer
class QuoteCheckMailerPreview < ActionMailer::Preview
  def created
    quote_check = QuoteCheck.order("RANDOM()").first
    QuoteCheckMailer.created(quote_check)
  end

  def created_from_email
    quote_check = QuoteCheck.order("RANDOM()").first
    QuoteCheckMailer.created_from_email(quote_check)
  end

  def results_available
    quote_check = QuoteCheck.order("RANDOM()").first
    QuoteCheckMailer.results_available(quote_check)
  end
end
