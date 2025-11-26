# frozen_string_literal: true

ActiveAdmin.register QuoteFile do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show, :view_file

  action_item :filter_by_file, only: :index do
    link_to "Retrouver par fichier", filter_by_file_admin_quote_files_path
  end

  collection_action :filter_by_file, method: %i[get post] do
    if request.post?
      if params[:file].present?
        file = params[:file]

        hexdigest = QuoteFile.hexdigest_for_file(file)
        quote_file = QuoteFile.find_by(hexdigest:) # filename: file.original_filename

        redirect_to admin_quote_file_path(quote_file) and return if quote_file

        flash.now[:alert] = "Aucun fichier de devis trouvé pour le fichier uploadé." # rubocop:disable Rails/I18nLocaleTexts
      else
        flash.now[:alert] = "Veuillez sélectionner un fichier à uploader." # rubocop:disable Rails/I18nLocaleTexts
      end
    end
  end

  config.filters = false
  config.sort_order = "created_at_desc"

  controller do
    def scoped_collection
      super.select(*(QuoteFile.column_names - ["data imagified_pages"]))
    end
  end

  member_action :view_file, method: :get do
    quote_file = QuoteFile.select(:data, :content_type, :filename).find(params[:id])

    send_data quote_file.content,
              filename: quote_file.filename,
              type: quote_file.content_type,
              disposition: "inline"
  end

  member_action :view_imagified_page, method: :get do
    quote_file = QuoteFile.select(:filename, :imagified_pages).find(params[:id])
    imagified_page = quote_file.imagified_pages[params[:page].to_i]

    send_data imagified_page,
              filename: "#{quote_file.filename}_page_#{params[:page].to_i}.png",
              type: "image/png",
              disposition: "inline"
  end

  index do # rubocop:disable Metrics/BlockLength
    id_column

    column :filename, sortable: :filename do
      if it.security_scan_good == false
        "#{it.filename} (⚠ virus)"
      else
        link_to it.filename, view_file_admin_quote_file_path(it, format: it.extension),
                target: "_blank", rel: "noopener"
      end
    end
    column :content_type
    column :ocr
    column :force_ocr
    column :security_scan_good do
      unless it.security_scan_good.nil?
        it.security_scan_good ? "Oui" : "Non"
      end
    end
    column :created_at, sortable: :created_at do
      local_time(it.created_at)
    end

    column "Nombre d'images de pages (si PDF)" do |quote_file|
      if quote_file.imagified_pages&.size&.positive?
        safe_join([
                    content_tag(:strong, "#{quote_file.imagified_pages.size} pages images : "),
                    quote_file.imagified_pages.each_with_index.map do |_, index|
                      safe_join([
                                  link_to((index + 1).to_s,
                                          view_imagified_page_admin_quote_file_path(quote_file, page: index),
                                          target: "_blank", rel: "noopener"),
                                  index < quote_file.imagified_pages.size - 1 ? content_tag(:span, " / ") : nil
                                ])
                    end
                  ])
      end
    end

    actions defaults: true do
      unless it.security_scan_good == false
        link_to it.filename, view_file_admin_quote_file_path(it, format: it.extension),
                target: "_blank", rel: "noopener"
      end
    end
  end

  show do # rubocop:disable Metrics/BlockLength
    attributes_table do # rubocop:disable Metrics/BlockLength
      row :id

      row :filename do
        if it.security_scan_good == false
          "#{it.filename} (⚠ virus)"
        else
          link_to it.filename, view_file_admin_quote_file_path(it, format: it.extension),
                  target: "_blank", rel: "noopener"
        end
      end
      row :content_type
      row :ocr
      row :force_ocr
      row :security_scan_good do
        unless it.security_scan_good.nil?
          it.security_scan_good ? "Oui" : "Non"
        end
      end
      row :created_at do
        local_time(it.created_at)
      end

      row "Nombre d'images de pages (si PDF)" do |quote_file|
        if quote_file.imagified_pages&.size&.positive?
          safe_join([
                      content_tag(:strong, "#{quote_file.imagified_pages.size} pages images : "),
                      quote_file.imagified_pages.each_with_index.map do |_, index|
                        safe_join([
                                    link_to((index + 1).to_s,
                                            view_imagified_page_admin_quote_file_path(quote_file, page: index),
                                            target: "_blank", rel: "noopener"),
                                    index < quote_file.imagified_pages.size - 1 ? content_tag(:span, " / ") : nil
                                  ])
                      end
                    ])
        end
      end

      row "Devis associés" do |quote_file|
        ul do
          quote_file.quote_checks.order(created_at: :desc).each do |quote_check|
            li do
              link_to "#{local_time(quote_check.created_at)} - Devis #{quote_check.id}",
                      admin_quote_check_path(quote_check),
                      target: "_blank", rel: "noopener"
            end
          end
        end
      end
    end

    if resource.imagified_pages&.size&.positive?
      table do
        tbody do
          resource.imagified_pages.each_with_index.map do |_, index|
            tr do
              td style: "width: 5%" do
                "Page #{index + 1}"
              end
              td style: "width: 95%; overflow: hidden; white-space: nowrap" do
                link_to view_imagified_page_admin_quote_file_path(resource, page: index), target: "_blank",
                                                                                          rel: "noopener" do
                  image_tag view_imagified_page_admin_quote_file_path(resource, page: index),
                            style: "width: 100%; max-width: 300px; height: auto; display: block"
                end
              end
            end
          end
        end
      end
    end

    tabs do
      if resource.ocr_result.present?
        tab "OCR Result" do
          pre JSON.pretty_generate(resource.ocr_result)
        end
      end

      instance_exec(&processing_logs_tab(resource))
    end
  end
end
