# frozen_string_literal: true

# rubocop:disable Rails/I18nLocaleTexts
ActiveAdmin.register QuoteCheck do
  member_action :recheck, method: :post do
    quote_check = QuoteCheck.find(params[:id])

    if quote_check.recheckable?
      QuoteCheckCheckJob.perform_later(quote_check.id)
      flash[:success] = "Le devis est en cours de retraitement."
    else
      flash[:error] = "Le devis ne peut pas être retraité."
    end

    redirect_to admin_quote_check_path(quote_check)
  end
end
# rubocop:enable Rails/I18nLocaleTexts
