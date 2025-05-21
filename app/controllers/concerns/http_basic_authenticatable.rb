# frozen_string_literal: true

# Add HTTP Auth Basic
module HttpBasicAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate, if: -> { http_basic_auth_enabled? }
  end

  protected

  def authenticate
    authenticate_or_request_with_http_basic("Administration") do |username, password|
      username == ENV.fetch("MDSO_SITE_USER", "mdso") && password == ENV.fetch("MDSO_SITE_PASSWORD")
    end
  end

  def http_basic_auth_enabled?
    ENV.key?("MDSO_SITE_PASSWORD") && !Rails.env.test?
  end
end
