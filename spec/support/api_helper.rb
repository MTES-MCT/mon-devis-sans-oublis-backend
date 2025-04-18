# frozen_string_literal: true

# Helper to encode HTTP Basic Auth credentials
module ApiHelper
  def api_key_header
    { "Authorization" => "Bearer #{ENV.fetch('MDSO_API_KEY_FOR_TEST')}" }
  end

  def api_key_mdso_header
    { "Authorization" => "Bearer #{ENV.fetch('MDSO_API_KEY_FOR_MDSO')}" }
  end

  # Old DEPRECATED way
  def basic_auth_header(username: "mdso", password: ENV.fetch("MDSO_SITE_PASSWORD"))
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    { "Authorization" => credentials }
  end
end
