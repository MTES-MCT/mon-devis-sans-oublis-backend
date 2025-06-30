# frozen_string_literal: true

# Enure only one button display
ActiveAdmin.register QuoteCheck do
  action_item :recheck, only: :show do
    link_to "Re-vérifier à nouveau", recheck_admin_quote_check_path(resource), method: :post if resource.recheckable?
  end
end

Rails.root.glob("app/admin/quote_checks/*.rb").each { |f| require f }
