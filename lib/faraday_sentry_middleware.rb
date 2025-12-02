# frozen_string_literal: true

# This middleware captures Faraday HTTP requests and adds them as breadcrumbs to Sentry.
# Since http_logger option only works for standard net/http library
# See https://docs.sentry.io/platforms/ruby/guides/rails/configuration/options/#breadcrumbs_logger
class FaradaySentryMiddleware < Faraday::Middleware
  def call(request_env) # rubocop:disable Metrics/MethodLength
    @app.call(request_env).on_complete do |response_env|
      Sentry.add_breadcrumb(
        Sentry::Breadcrumb.new(
          category: "http",
          level: response_env.status >= 400 ? "warning" : "info",
          data: {
            method: request_env.method.upcase,
            url: request_env.url.to_s,
            status_code: response_env.status,
            duration: response_env.response_headers["x-total-time"].to_f.round(3)
          }
        )
      )
    end
  end
end
