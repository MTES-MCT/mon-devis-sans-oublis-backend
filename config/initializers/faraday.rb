# frozen_string_literal: true

require_relative "../../lib/faraday_sentry_middleware"

Faraday::Middleware.register_middleware(
  sentry_breadcrumb: -> { FaradaySentryMiddleware }
)

# Override Faraday.new globally
module FaradayPatch
  def new(url = nil, **, &block)
    super do |faraday|
      faraday.use :sentry_breadcrumb # Auto-inject
      block&.call(faraday)
    end
  end
end

Faraday.singleton_class.prepend(FaradayPatch)
