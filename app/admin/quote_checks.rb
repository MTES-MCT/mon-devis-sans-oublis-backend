# frozen_string_literal: true

def geste_errors(quote_check, geste_index)
  geste_id = QuoteValidator::Base.geste_index(
    quote_check.id, geste_index
  )
  quote_check.validation_error_details&.select { |error| error["geste_id"] == geste_id }
end

# rubocop:disable Rails/I18nLocaleTexts
ActiveAdmin.register QuoteCheck do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show, :edit, :update, :new, :create

  permit_params :expected_validation_errors,
                :file,
                :parent_id,
                :reference,
                :profile,
                :aides, :gestes, # Virtual attributes
                :ocr, :qa_llm # Check params

  filter :reference, as: :string
  filter :file_filename, as: :string
  filter :created_at, as: :date_range
  filter :source_name, as: :select, collection:
    ActiveRecord::Base.connected? && QuoteCheck.connection.data_source_exists?(QuoteCheck.table_name) ? # rubocop:disable Style/MultilineTernaryOperator
      QuoteCheck.distinct.pluck(:source_name).sort : []

  filter :status, as: :select, collection: QuoteCheck::STATUSES
  filter :profile, as: :select, collection: QuoteCheck::PROFILES

  config.sort_order = "created_at_desc"

  scope "tous", :all, default: true
  scope "avec valeurs test", :with_expected_value
  scope "fichier en erreur", :with_file_error
  scope "devis avec corrections", :with_edits

  controller do # rubocop:disable Metrics/BlockLength
    # Overwrite "includes :file, :feedbacks" to not load full File data
    def scoped_collection # rubocop:disable Metrics/MethodLength
      hidable_fields = if params[:action] == "index"
                         %w[
                           text anonymised_text
                           file_text file_markdown
                         ]
                       else
                         []
                       end

      super.eager_load(:file, :feedbacks)
           .select(
             *(QuoteCheck.column_names - (hidable_fields || [])).map { "#{QuoteCheck.table_name}.#{it}" },
             "#{QuoteCheckFeedback.table_name}.id AS feedback_id",
             *(QuoteFile.column_names - %w[id data imagified_pages]).map { "#{QuoteFile.table_name}.#{it}" }
           )
    end

    # rubocop:disable Metrics/AbcSize
    def create # rubocop:disable Metrics/MethodLength
      upload_file = new_quote_check_params[:file]
      if upload_file.blank?
        flash.now[:error] = "Veuillez sélectionner un fichier"
        build_resource
        render :new, status: :unprocessable_entity
        return
      end

      quote_check_service = QuoteCheckService.new(
        upload_file.tempfile, upload_file.original_filename,
        new_quote_check_params[:profile],
        file_text: new_quote_check_params[:file_text],
        file_markdown: new_quote_check_params[:file_markdown],
        metadata: QuoteCheck.new(
          aides: new_quote_check_params[:aides],
          gestes: new_quote_check_params[:gestes]
        ).metadata,
        parent_id: new_quote_check_params[:parent_id],
        reference: new_quote_check_params[:reference],
        source_name: "mdso_bo"
      )

      @quote_check = quote_check_service.quote_check
      if @quote_check
        QuoteFileSecurityScanJob.perform_later(@quote_check.file.id)
        QuoteCheckCheckJob.perform_later(
          @quote_check.id,
          force_ocr: ActiveModel::Type::Boolean.new.cast(new_quote_check_params[:force_ocr]),
          ocr: new_quote_check_params[:ocr],
          qa_llm: new_quote_check_params[:qa_llm]
        )
        redirect_to admin_quote_check_path(@quote_check), notice: "Devis uploadé, en cours d'analyse."
      else
        flash.now[:error] = "Erreur dans les données du devis"
        build_resource
        render :new, status: :unprocessable_entity
      end
    end
    # rubocop:enable Metrics/AbcSize

    def update # rubocop:disable Metrics/MethodLength
      quote_check = resource

      begin
        # TODO: Find a proper way to parse JSON and reuse super
        quote_check.expected_validation_errors = if params[:quote_check][:expected_validation_errors].presence
                                                   JSON.parse(params[:quote_check][:expected_validation_errors])
                                                 end
      rescue JSON::ParserError
        redirect_to edit_admin_quote_check_path, alert: "Invalid JSON format" and return
      end

      if quote_check.save
        redirect_to admin_quote_check_path(quote_check), notice: "Quote check updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def new_quote_check_params
      params.require(:quote_check).permit(
        :file, :parent_id, :profile,
        :file_text, :file_markdown,
        :reference,
        :force_ocr, :ocr, :qa_llm, # Check params
        aides: [], gestes: [] # Virtual attributes
      )
    end
  end

  member_action :recheck, method: :post do
    quote_check = QuoteCheck.find(params[:id])

    if quote_check.recheckable?
      QuoteCheckCheckJob.perform_later(quote_check.id)
      flash[:success] = "Le devis est en cours de retraitement."
    else
      flash[:error] = "Le devis ne peut pas être retraité."
    end

    redirect_to admin_quote_check_path(quote_check)
  end

  action_item :recheck, only: :show do
    link_to "Re-vérifier à nouveau", recheck_admin_quote_check_path(resource), method: :post if resource.recheckable?
  end

  index do # rubocop:disable Metrics/BlockLength
    id_column do
      link_to "Devis #{it.id}", admin_quote_check_path(it)
    end

    column "Nom de fichier" do
      if it.file
        if it.file.security_scan_good == false
          "#{it.file.filename} (⚠ virus)"
        else
          link_to it.file.filename, view_file_admin_quote_file_path(it.file, format: it.file.extension),
                  target: "_blank", rel: "noopener"
        end
      end
    end

    column "Date soumission", &:started_at

    column "Source", :source_name
    column "Référence", :reference

    column "Statut", :status

    column "Correction" do
      link_to "Devis #{it.id}", it.frontend_webapp_url,
              target: "_blank", rel: "noopener"
    end

    column "Gestes demandés" do
      it.metadata&.dig("gestes")&.join("\n")
    end

    column "Gestes détectés" do
      it.read_attributes&.dig("gestes")&.map { it["type"] }&.uniq&.join("\n")
    end

    column "Aides demandées" do
      it.metadata&.dig("aides")&.join("\n")
    end

    column "Nb points de contrôle", &:validation_controls_count

    column "Nb erreurs" do
      it.validation_errors&.count
    end

    column "Feedback ?" do
      it.feedbacks.any?
    end

    column "Commentaire ?", &:commented?

    column "Date édition", &:edited_at

    column "Persona", :profile
    column :force_ocr
    column :ocr
    column :qa_llm
    column "Nb tokens" do
      number_with_delimiter(it.tokens_count, delimiter: " ")
    end
    column "temps traitement" do
      "#{it.processing_time.ceil(1)}s" if it.processing_time
    end

    actions defaults: false do
      link_to "Voir détail", admin_quote_check_path(it), class: "button"
    end
  end

  show do # rubocop:disable Metrics/BlockLength
    columns do # rubocop:disable Metrics/BlockLength
      column do # rubocop:disable Metrics/BlockLength
        attributes_table do # rubocop:disable Metrics/BlockLength
          row "Nom de fichier" do
            if resource.file.security_scan_good == false
              "#{resource.file.filename} (⚠ virus)"
            else
              link_to resource.file.filename,
                      view_file_admin_quote_file_path(resource.file, format: resource.file.extension),
                      target: "_blank", rel: "noopener"
            end
          end

          row "Date de soumission" do
            resource.started_at
          end

          row :source_name, lael: "Source"
          row :reference, label: "Référence"
          row :status, lael: "Statut"
          row :profile, label: "Persona"
          row :force_ocr
          row :ocr
          row :qa_llm
          row :file_text
          row :file_markdown
          row :tokens_count, "Nombre de tokens" do
            number_with_delimiter(it.tokens_count, delimiter: " ")
          end
          row "temps traitement (de soumission à fin d'analyse auto)" do
            "#{resource.processing_time.ceil(1)}s" if resource.processing_time
          end

          row "Gestes demandés" do
            it.metadata&.dig("gestes")&.join("\n")
          end

          row "Gestes détectés" do
            it.read_attributes&.dig("gestes")&.map { it["type"] }&.uniq&.join("\n")
          end

          row "Aides demandées" do
            it.metadata&.dig("aides")&.join("\n")
          end

          row "Nombre de points de contrôle", &:validation_controls_count

          row "Nombre d'erreurs" do
            it.validation_errors&.count
          end

          row "Correction" do
            link_to "Devis #{it.id}", it.frontend_webapp_url,
                    target: "_blank", rel: "noopener"
          end

          row "Présence de feedback ?" do
            it.feedbacks.any?
          end

          row "Présence de commentaire ?", &:commented?

          row "Date de dernière édition", &:edited_at

          row :comment, label: "Commentaire global"

          row "version application" do
            if resource.application_version && resource.application_version != "unknown"
              link_to resource.application_version,
                      "https://github.com/betagouv/mon-devis-sans-oublis-backend/tree/#{resource.application_version}",
                      target: "_blank", rel: "noopener"
            end
          end

          row "expected_validation_errors" do
            pre JSON.pretty_generate(resource.expected_validation_errors) if resource.expected_validation_errors
          end
        end
      end

      column do
        panel "Process théorique" do
          content_tag(:table) do
            [
              content_tag(:tr) do
                content_tag(:td, "1.") +
                  content_tag(
                    :td,
                    "Texte brut (en // détectection virus via Clam AV pour ne pas afficher dans BO si risque)"
                  )
              end,
              content_tag(:tr) do
                content_tag(:td, "2.") + content_tag(:td, "Données privées via méthode naïve hors ligne")
              end,
              content_tag(:tr) do
                content_tag(:td, "3.") + content_tag(:td, "Données privées et Attributs via par Albert (Gouv)")
              end,
              content_tag(:tr) do
                content_tag(:td, "4.") + content_tag(:td, "Texte Anonymisé")
              end,
              content_tag(:tr) do
                content_tag(:td, "5.") + content_tag(:td, "Attributs via par Mistral")
              end,
              content_tag(:tr) do
                content_tag(:td, "6.") + content_tag(:td, "Retour API pour frontend")
              end
            ].join.html_safe # rubocop:disable Rails/OutputSafety
          end
        end
      end
    end

    tabs do # rubocop:disable Metrics/BlockLength
      if resource.feedbacks.any?
        tab "Feedbacks" do
          table do
            thead do
              tr do
                th "Courriel"
                th "Note (globale)"
                th "Ligne en erreur dans devis (si feedback spécifique)"
                th "Commentaire"
              end
            end
            tbody do
              resource.feedbacks.each do |feedback|
                tr do
                  td feedback.email
                  td feedback.rating
                  td feedback.provided_value
                  td feedback.comment
                end
              end
            end
          end
        end
      end

      tab "Attributs détectés" do # rubocop:disable Metrics/BlockLength
        file_errors = resource.validation_error_details&.select { |error| error["category"] == "file" }
        if file_errors&.any?
          panel "Fichier" do # rubocop:disable Metrics/BlockLength
            table_for [nil] do # rubocop:disable Metrics/BlockLength
              column "Erreur(s) et correction(s)" do
                content_tag(:ul) do
                  file_errors.map do
                    content = "#{it.fetch('code')} : #{it.fetch('title')} #{it.fetch('id')}"

                    edit = resource.validation_error_edits&.dig(it.fetch("id"))
                    if edit
                      deletion_reason = edit["reason"]
                      if deletion_reason
                        deletion_reason = I18n.t(
                          "quote_checks.validation_error_detail_deletion_reasons.#{deletion_reason}",
                          default: deletion_reason
                        )
                      end

                      content = safe_join([
                        content,
                        content_tag(:br),
                        if edit.key?("comment")
                          content_tag(:strong,
                                      ["\nCommentaire", edit.fetch("comment")].compact.join(" : "))
                        end,
                        if edit.key?("deleted_at")
                          content_tag(:strong,
                                      ["\nSupprimée", deletion_reason].compact.join(" : "))
                        end
                      ].compact)
                    end

                    concat(content_tag(:li, content))
                  end
                end
              end
            end
          end
        end

        panel "Admin" do # rubocop:disable Metrics/BlockLength
          table_for [nil] do # rubocop:disable Metrics/BlockLength
            column "Erreur(s) et correction(s)" do # rubocop:disable Metrics/BlockLength
              admin_errors = resource.validation_error_details&.select { |error| error["category"] == "admin" }

              if admin_errors&.any?
                content_tag(:ul) do
                  admin_errors.map do
                    content = "#{it.fetch('code')} : #{it.fetch('title')} #{it.fetch('id')}"

                    edit = resource.validation_error_edits&.dig(it.fetch("id"))
                    if edit
                      deletion_reason = edit["reason"]
                      if deletion_reason
                        deletion_reason = I18n.t(
                          "quote_checks.validation_error_detail_deletion_reasons.#{deletion_reason}",
                          default: deletion_reason
                        )
                      end

                      content = safe_join([
                        content,
                        content_tag(:br),
                        if edit.key?("comment")
                          content_tag(:strong,
                                      ["\nCommentaire", edit.fetch("comment")].compact.join(" : "))
                        end,
                        if edit.key?("deleted_at")
                          content_tag(:strong,
                                      ["\nSupprimée", deletion_reason].compact.join(" : "))
                        end
                      ].compact)
                    end

                    concat(content_tag(:li, content))
                  end
                end
              end
            end
          end
        end

        panel "Gestes" do # rubocop:disable Metrics/BlockLength
          gestes = resource.read_attributes&.dig("gestes")

          if gestes&.any?
            table_for gestes.each_with_index do # rubocop:disable Metrics/BlockLength
              column "Type" do |geste,|
                geste["type"]
              end
              column "Attributs" do |geste,|
                pre JSON.pretty_generate(geste)
              end
              column "Erreur(s) et correction(s)" do |_, geste_index| # rubocop:disable Metrics/BlockLength
                current_geste_errors = geste_errors(resource, geste_index)

                if current_geste_errors&.any?
                  content_tag(:ul) do
                    current_geste_errors.map do
                      content = "#{it.fetch('code')} : #{it.fetch('title')} #{it.fetch('id')}"

                      edit = resource.validation_error_edits&.dig(it.fetch("id"))
                      if edit
                        deletion_reason = edit["reason"]
                        if deletion_reason # rubocop:disable Metrics/BlockNesting
                          deletion_reason = I18n.t(
                            "quote_checks.validation_error_detail_deletion_reasons.#{deletion_reason}",
                            default: deletion_reason
                          )
                        end

                        content = safe_join([
                          content,
                          content_tag(:br),
                          if edit.key?("comment") # rubocop:disable Metrics/BlockNesting
                            content_tag(:strong,
                                        ["\nCommentaire", edit.fetch("comment")].compact.join(" : "))
                          end,
                          if edit.key?("deleted_at") # rubocop:disable Metrics/BlockNesting
                            content_tag(:strong,
                                        ["\nSupprimée", deletion_reason].compact.join(" : "))
                          end
                        ].compact)
                      end

                      concat(content_tag(:li, content))
                    end
                  end
                end
              end
            end
          end
        end

        panel "Administratifs (hors données ADEME)" do
          if (attributes = resource.read_attributes&.except("extended_data", "gestes"))
            attributes_table_for attributes do
              attributes.each do |key, value|
                row key.to_s.humanize do
                  simplest_value = value.is_a?(Array) && value.size == 1 ? value.first : value
                  if simplest_value.is_a?(Hash) || simplest_value.is_a?(Array)
                    pre JSON.pretty_generate(simplest_value)
                  else
                    simplest_value
                  end
                end
              end
            end
          end
        end
      end

      tab "1. Texte brut#{resource.ocrable? ? " (via #{resource.ocr})" : ''}" do
        pre resource.text
      end

      tab "2. Données privées via méthode naïve hors ligne" do
        pre JSON.pretty_generate(resource.naive_attributes)
      end

      tab "3. Données privées et Attributs via par Albert (Gouv)" do
        pre JSON.pretty_generate(resource.private_data_qa_attributes)

        h1 "Résultat technique brut"
        pre JSON.pretty_generate(resource.private_data_qa_result)
      end

      tab "4. Texte Anonymisé" do
        pre resource.anonymised_text
      end

      tab "5. Attributs via par Mistral" do
        pre JSON.pretty_generate(resource.qa_attributes)

        h1 "Résultat technique brut"
        pre JSON.pretty_generate(resource.qa_result)
      end

      tab "6. Retour API pour frontend" do
        pre JSON.pretty_generate(
          QuoteCheckSerializer.new(resource).as_json
        )
      end
    end
  end

  form do |f| # rubocop:disable Metrics/BlockLength
    f.inputs "QuoteCheck Details" do # rubocop:disable Metrics/BlockLength
      if f.object.new_record?
        f.input :profile,
                as: :select,
                collection: QuoteCheck::PROFILES,
                include_blank: false,
                selected: (QuoteCheck::PROFILES & ["conseiller"]).first || QuoteCheck::PROFILES.first
        f.input :file, as: :file

        f.input :gestes,
                as: :select,
                collection: QuoteCheck.metadata_values("gestes"),
                include_blank: false,
                multiple: true
        f.input :aides,
                as: :select,
                collection: QuoteCheck.metadata_values("aides"),
                include_blank: false,
                multiple: true

        if QuoteCheck.count.positive?
          f.input :parent_id,
                  as: :select,
                  collection: QuoteCheck.order(created_at: :desc).all.map { [it.id, it.id] }
        end

        hr

        f.input :reference

        f.input :force_ocr,
                as: :boolean,
                label: "Forcer l'OCR",
                hint: "Forcer l'OCR même si le fichier est déjà PDF"

        f.input :ocr,
                as: :select,
                collection: Rails.application.config.ocrs_configured,
                include_blank: false,
                selected: f.object&.ocr ||
                          Rails.application.config.ocrs_configured.detect { # rubocop:disable Style/BlockDelimiters
                            it.match(/#{QuoteReader::Global::DEFAULT_OCR}/i)
                          } ||
                          Rails.application.config.ocrs_configured.first

        f.input :qa_llm,
                as: :select,
                collection: Rails.application.config.llms_configured,
                include_blank: false,
                selected: f.object&.qa_llm ||
                          Rails.application.config.llms_configured.detect { # rubocop:disable Style/BlockDelimiters
                            it.match(/#{QuoteReader::Qa::DEFAULT_LLM}/i)
                          } ||
                          Rails.application.config.llms_configured.first

        f.input :file_text, as: :text
        f.input :file_markdown, as: :text
      end

      unless f.object.new_record?
        expected_validation_errors = f.object.expected_validation_errors.presence ||
                                     f.object.validation_errors
        f.input :expected_validation_errors,
                input_html: {
                  value: expected_validation_errors ? JSON.pretty_generate(expected_validation_errors) : ""
                }
      end
    end
    f.actions
  end
end
# rubocop:enable Rails/I18nLocaleTexts
