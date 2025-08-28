# frozen_string_literal: true

require_relative "../../lib/tools/uri_extended"

frontend_origins = [
  if Rails.env.production?
    UriExtended.host_with_port(ENV.fetch("FRONTEND_APPLICATION_HOST"))
  else
    "*"
  end
]
frontend_origins << %r{\Ahttp://localhost(:\d+)?\z} if Rails.application.config.app_env == "staging"

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*Array.wrap(frontend_origins))

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: Rails.env.production?
  end
end
