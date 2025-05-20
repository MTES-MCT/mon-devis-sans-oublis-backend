# frozen_string_literal: true

ActiveAdmin.register QuotesCase do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show, :new, :create

  permit_params :reference

  filter :created_at, as: :date_range

  filter :reference, as: :string
  filter :profile, as: :select, collection: QuotesCase::PROFILES
  filter :renovation_type, as: :select, collection: QuotesCase::RENOVATION_TYPES

  filter :source_name, as: :select, collection:
    ActiveRecord::Base.connected? && QuotesCase.connection.data_source_exists?(QuotesCase.table_name) ? # rubocop:disable Style/MultilineTernaryOperator
      QuotesCase.distinct.pluck(:source_name).sort : []

  config.sort_order = "created_at_desc"

  index do
    id_column do
      link_to "Dossier #{it.id}", admin_quotes_case_path(it)
    end

    column "Source", :source_name
    column "Référence", :reference
    column :created_at

    column "Persona", :profile
    column "Type de rénovation", :renovation_type
  end

  show do
    columns do
      column do
        attributes_table do
          row :source_name, label: "Source"
          row :reference, label: "Référence"
          row :created_at

          row :profile, label: "Persona"
          row :renovation_type, label: "Type de rénovation"

          row :status

          row :quote_checks do |quote_case|
            content_tag(:ul) do
              quote_case.quote_checks.default_order.map do |quote_check|
                content_tag(:li, link_to(
                                   quote_check.file.filename,
                                   admin_quote_check_path(quote_check),
                                   target: "_blank", rel: "noopener"
                                 ))
              end.join.html_safe # rubocop:disable Rails/OutputSafety
            end
          end

          row :updated_at
        end
      end
    end
  end

  form do |f|
    f.inputs "QuotesCase" do
      f.input :profile,
              as: :select,
              collection: QuotesCase::PROFILES,
              include_blank: false,
              selected: (QuotesCase::PROFILES & ["conseiller"]).first || QuotesCase::PROFILES.first
      f.input :renovation_type,
              as: :select,
              collection: QuotesCase::RENOVATION_TYPES,
              include_blank: false,
              selected: (QuotesCase::RENOVATION_TYPES & ["geste"]).first ||
                        QuotesCase::RENOVATION_TYPES.first

      f.input :reference

      f.actions
    end
  end
end
