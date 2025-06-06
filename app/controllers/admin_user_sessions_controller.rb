# frozen_string_literal: true

# Manage Admin user sessions for the back office
class AdminUserSessionsController < ApplicationController
  ADMIN_EMAILS = ENV.fetch("ADMIN_EMAILS", "").split(",")

  prepend_view_path "app/views/admin_user/sessions"

  skip_before_action :authenticate_admin_user!, only: %i[new create destroy]

  def new
    render "admin_user/sessions/new", layout: false
  end

  def create # rubocop:disable Metrics/MethodLength
    auth = request.env["omniauth.auth"]

    email = if auth.nil? && Rails.env.development?
              "dev@localhost"
            else
              auth.info.email
            end

    if ADMIN_EMAILS.include?(email)
      session[:admin_user] = email
      redirect_to admin_root_path
    else
      render plain: "Unauthorized", status: :unauthorized
    end
  end

  def destroy
    reset_session
    redirect_to login_path
  end

  def failure
    render plain: "Authentication failed", status: :unauthorized
  end
end
