# frozen_string_literal: true

# rubocop:disable Rails/I18nLocaleTexts
ActiveAdmin.register QuoteCheck do
  member_action :rnt, method: :post do
    quote_check_id = params[:id]
    quote_check = QuoteCheck.find_by(id: quote_check_id)

    if RntValidatorService.rnt_validable?(quote_check)
      QuoteCheckRntValidateJob.perform_later(quote_check_id)
      flash[:success] = "Le devis est en cours de test au RNT. Raffraîchissez la page dans quelques instants."
    else
      flash[:error] = "Le devis ne peut pas être testé au RNT."
    end

    redirect_to admin_quote_check_path(quote_check_id)
  end
end
# rubocop:enable Rails/I18nLocaleTexts
