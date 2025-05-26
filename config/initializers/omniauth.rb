# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV.key? "PROCONNECT_CLIENT_ID"
    provider(
      :proconnect,
      {
        client_id: ENV.fetch("PROCONNECT_CLIENT_ID"),
        client_secret: ENV.fetch("PROCONNECT_CLIENT_SECRET"),
        proconnect_domain: ENV.fetch("PROCONNECT_DOMAIN"), # integration or production
        redirect_uri: URI.join(ENV.fetch("APPLICATION_HOST"), "/auth/proconnect/callback").to_s,
        # post_logout_redirect_uri
        # See https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/donnees_fournies
        scope: "openid email idp_id organizational_unit belonging_population"
      }
    )
  end
end
