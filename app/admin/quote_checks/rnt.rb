# frozen_string_literal: true

# rubocop:disable Rails/I18nLocaleTexts
ActiveAdmin.register QuoteCheck do
  member_action :rnt, method: :post do
    quote_check_id = params[:id]

    begin
      rnt_validation = RntValidatorService.new(quote_check_id).validate

      # Save in Redis cache for 1 day to display it.
      Kredis.json("rnt:#{quote_check_id}").tap do |cache_key|
        cache_key.value = rnt_validation
        cache_key.expires_in = 1.day
      end

      flash[:success] = "Le devis a été test au RNT."
    rescue RntValidatorService::NotProcessableError
      flash[:error] = "Le devis ne peut pas être testé au RNT."
    end

    redirect_to admin_quote_check_path(quote_check_id)
  end
end
# rubocop:enable Rails/I18nLocaleTexts
