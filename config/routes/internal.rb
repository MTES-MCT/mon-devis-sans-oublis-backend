# frozen_string_literal: true

# Back Office and technical dashboards routes
Rails.application.routes.draw do
  scope "mdso" do
    ActiveAdmin.routes(self)
  end

  # Easy way to access the back office
  get "login", to: "admin_user_sessions#new", as: :login
  get "logout", to: "admin_user_sessions#destroy", as: :logout

  get "auth/proconnect", to: "admin_user_sessions#new", as: :new_admin_user_session
  post "auth/proconnect", as: :proconnect_omniauth_authorize
  get "auth/:provider/callback", to: "admin_user_sessions#create"
  get "auth/failure", to: "admin_user_sessions#failure", as: :auth_failure
  delete "auth/proconnect", to: "admin_user_sessions#destroy", as: :destroy_admin_user_session

  mount GoodJob::Engine => "mdso_good_job"
end
