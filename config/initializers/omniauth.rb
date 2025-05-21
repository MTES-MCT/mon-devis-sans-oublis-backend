# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV.key? "PROCONNECT_CLIENT_ID"
    provider(
      :proconnect,
      {
        client_id: ENV.fetch("PROCONNECT_CLIENT_ID"),
        client_secret: ENV.fetch("PROCONNECT_CLIENT_SECRET"),
        #   proconnect_domain: ENV.fetch("YOUR_APP_PC_HOST"),
        #   redirect_uri: ENV.fetch("YOUR_APP_PC_REDIRECT_URI"),
        #   post_logout_redirect_uri: ENV.fetch("YOUR_APP_PC_POST_LOGOUT_REDIRECT_URI"),
        scope: "email"
      }
    )
  end
end
