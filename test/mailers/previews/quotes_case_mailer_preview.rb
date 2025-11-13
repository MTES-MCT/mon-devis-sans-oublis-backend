# frozen_string_literal: true

# Mail previews for QuotesCaseMailer
class QuotesCaseMailerPreview < ActionMailer::Preview
  def created_from_email
    quotes_case = QuotesCase.order("RANDOM()").first
    QuotesCaseMailer.created_from_email(quotes_case)
  end

  def results_available
    quotes_case = QuotesCase.order("RANDOM()").first
    QuotesCaseMailer.results_available(quotes_case)
  end
end
