# frozen_string_literal: true

ActiveAdmin.register QuotesCase do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show, :new, :create

  permit_params :reference

  filter :reference, as: :string
  filter :source_name, as: :select, collection:
    QuoteCheck.connection.data_source_exists?(QuoteCheck.table_name) ? QuoteCheck.distinct.pluck(:source_name).sort : []

  config.sort_order = "created_at_desc"

  index do
    id_column do
      link_to "Dossier #{it.id}", admin_quotes_case_path(it)
    end

    column "Source", :source_name
    column "Référence", :reference
  end

  show do
    columns do
      column do
        attributes_table do
          row :source_name, label: "Source"
          row :reference, label: "Référence"
        end
      end
    end
  end

  form do |f|
    f.inputs "QuotesCase" do
      f.input :reference
      f.actions
    end
  end
end
