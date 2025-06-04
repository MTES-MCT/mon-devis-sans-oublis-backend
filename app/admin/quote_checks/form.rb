# frozen_string_literal: true

# rubocop:disable Rails/I18nLocaleTexts
ActiveAdmin.register QuoteCheck do # rubocop:disable Metrics/BlockLength
  permit_params :expected_validation_errors,
                :file,
                :parent_id,
                :reference, :profile, :renovation_type,
                :aides, :gestes, # Virtual attributes
                :ocr, :qa_llm # Check params

  controller do # rubocop:disable Metrics/BlockLength
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
        new_quote_check_params[:renovation_type],
        file_text: new_quote_check_params[:file_text],
        file_markdown: new_quote_check_params[:file_markdown],
        metadata: QuoteCheck.new(
          aides: new_quote_check_params[:aides],
          gestes: new_quote_check_params[:gestes]
        ).metadata,
        case_id: new_quote_check_params[:case_id],
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
        :file, :case_id, :parent_id,
        :reference, :profile, :renovation_type,
        :file_text, :file_markdown,
        :force_ocr, :ocr, :qa_llm, # Check params
        aides: [], gestes: [] # Virtual attributes
      )
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
        f.input :renovation_type,
                as: :select,
                collection: QuoteCheck::RENOVATION_TYPES,
                include_blank: false,
                selected: (QuoteCheck::RENOVATION_TYPES & ["geste"]).first ||
                          QuoteCheck::RENOVATION_TYPES.first
        f.input :case_id, as: :string, label: "ID du dossier"
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
