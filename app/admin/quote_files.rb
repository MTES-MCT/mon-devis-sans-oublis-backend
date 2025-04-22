# frozen_string_literal: true

ActiveAdmin.register QuoteFile do # rubocop:disable Metrics/BlockLength
  config.per_page = 10

  actions :index, :show, :view_file

  config.filters = false
  config.sort_order = "created_at_desc"

  controller do
    def scoped_collection
      super.select(*(QuoteFile.column_names - ["data imagified_pages"]))
    end
  end

  member_action :view_file, method: :get do
    quote_file = QuoteFile.select(:filename, :content_typ, :data).find(params[:id])

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

    column :filename do
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
    column :created_at

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
      row :created_at

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
  end
end
