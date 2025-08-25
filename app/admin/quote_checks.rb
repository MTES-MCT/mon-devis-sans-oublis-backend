# frozen_string_literal: true

# Enure only one button display
ActiveAdmin.register QuoteCheck do
  action_item :recheck, only: :show do
    link_to "Re-vérifier à nouveau", recheck_admin_quote_check_path(resource), method: :post if resource.recheckable?
  end

  if Rails.env.development?
    action_item :recheck_synchronously, only: :show do
      if resource.recheckable?
        link_to "Re-vérifier à nouveau (synchrone)",
                recheck_admin_quote_check_path(resource, process_synchronously: true),
                method: :post
      end
    end
  end
end

Rails.root.glob("app/admin/quote_checks/*.rb").each { |f| require f }
