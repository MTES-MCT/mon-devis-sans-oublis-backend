# frozen_string_literal: true

ActiveAdmin.register_page "Jobs" do
  menu label: "Jobs", priority: 150, url: -> { good_job_path }
end
