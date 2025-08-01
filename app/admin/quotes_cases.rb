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

  controller do
    # Overwrite "includes :quote_checks" to not load full File data
    def scoped_collection
      super.eager_load(quote_checks: :file)
           .select(
             *QuotesCase.column_names.map { "#{QuotesCase.table_name}.#{it}" },
             *%w[id created_at file_id].map { "#{QuoteCheck.table_name}.#{it}" },
             *%w[id filename].map { "#{QuoteFile.table_name}.#{it}" }
           )
    end
  end

  index do
    id_column do
      link_to "Dossier #{it.id}", admin_quotes_case_path(it)
    end

    column "Nb devis" do
      it.quote_checks.count
    end
    column "Source", :source_name
    column "Référence", :reference
    column :created_at do
      local_time(it.created_at)
    end

    column "Persona", :profile
    column "Type de rénovation", :renovation_type
  end

  show do # rubocop:disable Metrics/BlockLength
    columns do # rubocop:disable Metrics/BlockLength
      column do
        attributes_table do
          row "Nb devis" do
            it.quote_checks.count
          end
          row :source_name, label: "Source"
          row :reference, label: "Référence"
          row :created_at do
            local_time(it.created_at)
          end

          row :profile, label: "Persona"
          row :renovation_type, label: "Type de rénovation"

          row :status

          row :quote_checks do |quotes_case|
            content_tag(:ul) do
              quotes_case.quote_checks.default_order.map do |quote_check|
                next unless quote_check.file

                content_tag(:li, link_to(
                                   quote_check.file.filename,
                                   admin_quote_check_path(quote_check),
                                   target: "_blank", rel: "noopener"
                                 ))
              end.join.html_safe # rubocop:disable Rails/OutputSafety
            end
          end

          row :updated_at do
            local_time(it.updated_at)
          end
        end
      end
    end

    tabs do
      tab "Retour API avec erreurs incohérence pour frontend" do
        pre JSON.pretty_generate(
          QuotesCaseSerializer.new(resource).as_json
        )
      end

      instance_exec(&processing_logs_tab(resource))
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
