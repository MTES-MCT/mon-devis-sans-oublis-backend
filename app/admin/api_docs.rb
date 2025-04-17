# frozen_string_literal: true

ActiveAdmin.register_page "API Docs" do
  menu label: "API Docs", priority: 200, url: -> { rswag_ui_path }
end
