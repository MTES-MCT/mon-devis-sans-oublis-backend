# frozen_string_literal: true

module Admin
  # Super charge ActiveAdmin with HTTP Basic Auth
  class ApplicationController < ActionController::Base
    # include HttpBasicAuthenticatable

    def authenticate_user_admin!
      redirect_to "/login" unless session[:user_admin]
    end

    def current_user_admin
      Struct.new(email: session[:user_admin]) if session[:user_admin]
    end
  end
end
