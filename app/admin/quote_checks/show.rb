# frozen_string_literal: true

ActiveAdmin.register QuoteCheck do # rubocop:disable Metrics/BlockLength
  action_item :recheck, only: :show do
    link_to "Re-vérifier à nouveau", recheck_admin_quote_check_path(resource), method: :post if resource.recheckable?
  end

  show do # rubocop:disable Metrics/BlockLength
    columns do # rubocop:disable Metrics/BlockLength
      column do # rubocop:disable Metrics/BlockLength
        attributes_table do # rubocop:disable Metrics/BlockLength
          row "Nom de fichier" do
            file_link = if resource.file.security_scan_good == false
                          "#{resource.file.filename} (⚠ virus)"
                        else
                          link_to resource.file.filename,
                                  view_file_admin_quote_file_path(resource.file, format: resource.file.extension),
                                  target: "_blank", rel: "noopener"
                        end

            safe_join([
                        file_link,
                        content_tag(:br),
                        link_to(it.file.id, admin_quote_file_path(it.file))
                      ])
          end

          row "Dossier" do
            link_to quote_check.case.id, admin_quotes_case_path(quote_check.case) if quote_check.case
          end
          row "Date de soumission" do
            local_time(it.started_at)
          end

          row :source_name, lael: "Source"
          row :reference, label: "Référence"
          row :status, lael: "Statut"
          row :profile, label: "Persona"
          row :renovation_type, label: "Type de rénovation"
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

          row "Points contrôlés" do
            it.validation_control_codes&.join("\n")
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

          row "Date de dernière édition" do
            local_time(it.edited_at)
          end

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

      column do # rubocop:disable Metrics/BlockLength
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
                content_tag(:td, "3.") +
                  content_tag(:td, "Données privées et Attributs via par #{resource.private_data_qa_llm}")
              end,
              content_tag(:tr) do
                content_tag(:td, "4.") + content_tag(:td, "Texte Anonymisé")
              end,
              content_tag(:tr) do
                content_tag(:td, "5.") + content_tag(:td, "Attributs via par #{resource.qa_llm}")
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

        panel "Administratifs (données ADEME uniquement)" do
          if (attributes = resource.read_attributes&.dig("extended_data"))
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

      tab "3. Données privées et Attributs via par #{resource.private_data_qa_llm}" do
        pre JSON.pretty_generate(resource.private_data_qa_attributes)

        h1 "Résultat technique brut"
        pre JSON.pretty_generate(resource.private_data_qa_result)
      end

      tab "4. Texte Anonymisé" do
        pre resource.anonymised_text
      end

      tab "5. Attributs via par #{resource.qa_llm}" do
        pre JSON.pretty_generate(resource.qa_attributes)

        h1 "Résultat technique brut"
        pre JSON.pretty_generate(resource.qa_result)
      end

      tab "6. Retour API pour frontend" do
        pre JSON.pretty_generate(
          QuoteCheckSerializer.new(resource).as_json
        )
      end

      instance_exec(&processing_logs_tab(resource))
    end
  end
end
