# frozen_string_literal: true

class AdminUserSessionsController < ApplicationController
  ADMIN_EMAILS = ENV.fetch("ADMIN_EMAILS", "").split(",")

  def create
    auth = request.env["omniauth.auth"]
    email = auth.info.email

    if ADMIN_EMAILS.include?(email)
      session[:user_admin] = email
      redirect_to admin_root_path
    else
      render plain: "Unauthorized", status: :unauthorized
    end
  end

  def destroy
    reset_session
    redirect_to "/"
  end
end
