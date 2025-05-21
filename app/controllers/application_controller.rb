# frozen_string_literal: true

# Main controller for the application
class ApplicationController < ActionController::Base
  # include HttpBasicAuthenticatable
  include AdminUserAuthenticatable

  before_action :authenticate_admin_user!
end
