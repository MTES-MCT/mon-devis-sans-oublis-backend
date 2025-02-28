# frozen_string_literal: true

# Back Office and technical dashboards routes
Rails.application.routes.draw do
  scope "mdso" do
    ActiveAdmin.routes(self)
  end

  mount GoodJob::Engine => "mdso_good_job"
end
