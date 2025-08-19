# frozen_string_literal: true

# Add AdminUser authentication
module AdminUserAuthenticatable
  extend ActiveSupport::Concern

  AdminUser = Struct.new(:email)

  included do
    before_action :authenticate_admin_user!

    helper_method :current_admin_user
  end

  protected

  def authenticate_admin_user!
    return if Rails.env.development?

    redirect_to new_admin_user_session_path unless session[:admin_user]
  end

  def current_admin_user
    AdminUser.new(email: session[:admin_user]) if session[:admin_user]
  end
end
