# frozen_string_literal: true

ActiveAdmin.register QuoteCheck do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show, :edit, :update, :new, :create

  filter :status, as: :select, collection: QuoteCheck::STATUSES

  filter :created_at, as: :date_range

  filter :source_name, as: :select, collection:
    ActiveRecord::Base.connected? && QuoteCheck.connection.data_source_exists?(QuoteCheck.table_name) ? # rubocop:disable Style/MultilineTernaryOperator
      QuoteCheck.distinct.pluck(:source_name).sort : []

  filter :reference, as: :string
  filter :profile, as: :select, collection: QuoteCheck::PROFILES
  filter :renovation_type, as: :select, collection: QuoteCheck::RENOVATION_TYPES

  filter :file_filename, as: :string

  config.sort_order = "created_at_desc"

  scope "tous", :all, default: true
  scope "tous devis OCRable", :ocrable
  scope "devis OCRable non OCRisé", :non_ocred
  scope "devis OCRisé", :ocred
  scope "avec valeurs test", :with_expected_value
  scope "fichier en erreur", :with_file_error
  scope "mauvais fichier", :with_file_type_error
  scope "devis avec corrections", :with_edits
  scope "devis avec contact email", :with_feedback_email
  scope "devis avec erreur prix", :with_price_error

  controller do
    # Overwrite "includes :file, :feedbacks" to not load full File data
    def scoped_collection # rubocop:disable Metrics/MethodLength
      hidable_fields = if params[:action] == "index"
                         %w[
                           text anonymized_text
                           file_text file_markdown
                         ]
                       else
                         []
                       end

      super.left_joins(:file, :feedbacks)
           .select(
             *(QuoteCheck.column_names - (hidable_fields || [])).map { "#{QuoteCheck.table_name}.#{it}" },
             *(QuoteFile.column_names - %w[id data imagified_pages]).map { "#{QuoteFile.table_name}.#{it}" },
             "#{QuoteCheckFeedback.table_name}.id AS feedback_id"
           )
    end
  end

  index do # rubocop:disable Metrics/BlockLength
    id_column do
      link_to "Devis #{it.id}", admin_quote_check_path(it)
    end

    column "Nom de fichier", sortable: "quote_files.filename" do
      if it.file
        if it.file.security_scan_good == false
          "#{it.file.filename} (⚠ virus)"
        else
          link_to it.file.filename, view_file_admin_quote_file_path(it.file, format: it.file.extension),
                  target: "_blank", rel: "noopener"
        end
      end
    end

    column "Dossier", :case_id do |quote_check|
      link_to quote_check.case.id, admin_quotes_case_path(quote_check.case) if quote_check.case
    end
    column "Date soumission", sortable: :started_at do
      local_time(it.started_at)
    end

    column "Source", :source_name
    column "Email", :email
    column "Référence", :reference

    column "Statut", :status

    column "Correction" do
      link_to "Devis #{it.id}", it.frontend_webapp_url(mtm_campaign: "backoffice"),
              target: "_blank", rel: "noopener"
    end

    column "Gestes demandés" do
      it.metadata&.dig("gestes")&.join("\n")
    end

    column "Gestes détectés" do
      it.read_attributes&.dig("gestes")&.pluck("type")&.uniq&.join("\n") # rubocop:disable Style/SafeNavigationChainLength
    end

    column "Aides demandées" do
      it.metadata&.dig("aides")&.join("\n")
    end

    column "Points contrôlés" do
      it.validation_control_codes&.join("\n")
    end
    column "Nb points de contrôle", &:validation_controls_count

    column "Nb erreurs" do
      it.validation_errors&.count
    end

    column "Feedback ?" do
      it.feedbacks.any?
    end

    column "Commentaire ?", &:commented?

    column "Date édition", sortable: :validation_error_edited_at do
      local_time(it.edited_at)
    end

    column "Persona", :profile
    column "Type de rénovation", :renovation_type

    column :force_ocr
    column :ocr_used
    column :works_data_qa_llm
    column "Nb tokens", sortable: :tokens_count do
      number_with_delimiter(it.tokens_count, delimiter: " ")
    end
    column "temps traitement" do
      "#{it.processing_time.ceil(1)}s" if it.processing_time
    end

    actions defaults: false do
      link_to "Voir détail", admin_quote_check_path(it), class: "button"
    end
  end
end
