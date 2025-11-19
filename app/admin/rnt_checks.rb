# frozen_string_literal: true

ActiveAdmin.register RntCheck do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show

  filter :sent_at, as: :date_range

  config.sort_order = "sent_at_desc"

  index do
    id_column
    column :quote_check do
      link_to "Devis #{it.quote_check_id}", admin_quote_check_path(it.quote_check_id)
    end
    column :sent_at do
      local_time(it.sent_at)
    end
    column :result_at do
      local_time(it.result_at)
    end
  end

  show do
    columns do
      column do
        attributes_table do
          row :id
          row :quote_check do
            link_to "Devis #{it.quote_check_id}", admin_quote_check_path(it.quote_check_id)
          end

          row :sent_at do
            local_time(it.sent_at)
          end
          row :sent_input_xml do
            pre Nokogiri::XML(it.sent_input_xml).to_xml(indent: 2)
          end

          row :result_at do
            local_time(it.result_at)
          end
          row :result_json do
            pre JSON.pretty_generate(it.result_json) if it.result_json
          end
        end
      end
    end
  end
end
