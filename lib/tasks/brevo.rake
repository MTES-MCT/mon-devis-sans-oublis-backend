# frozen_string_literal: true

namespace :brevo do
  desc "Setup webhook for Brevo inbound emails"
  task setup_webhook: :environment do |_t, _args|
    # Optional: delete all existing webhooks
    # BrevoApi.new.webhooks_list.map { brevo.webhook_delete(it.fetch("id")) }

    MdsoBrevo.upsert_webhook!
  end
end
