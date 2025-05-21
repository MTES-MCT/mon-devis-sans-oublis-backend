# frozen_string_literal: true

module Admin
  # Super charge ActiveAdmin with Authentication
  class ApplicationController < ActionController::Base
    # include HttpBasicAuthenticatable
    include AdminUserAuthenticatable

    before_action :authenticate_admin_user!
  end
end
