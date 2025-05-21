# frozen_string_literal: true

# Back Office and technical dashboards routes
Rails.application.routes.draw do
  scope "mdso" do
    get "/auth/:provider/callback", to: "admin_user_sessions#create"
    get "/logout", to: "admin_user_sessions#destroy"
    get "/login", to: redirect("/auth/proconnect")

    ActiveAdmin.routes(self)
  end

  mount GoodJob::Engine => "mdso_good_job"
end
