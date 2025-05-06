# frozen_string_literal: true

module Api
  module V1
    # Controller for QuoteChecks API
    class QuoteChecksController < BaseController
      before_action :authorize_request, except: %i[metadata update]
      before_action :authorize_internal_mdso_only, only: :update

      before_action :quote_check, except: %i[create metadata]

      def show
        # Force to use async way by using show to get other fields
        render json: quote_check_json
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def create
        upload_file = quote_check_params[:file]

        if upload_file.blank?
          api_error("No file uploaded", nil, :unprocessable_entity)
          return
        end

        quote_check_service = QuoteCheckService.new(
          upload_file.tempfile, upload_file.original_filename,
          quote_check_params[:profile],
          file_text: quote_check_params[:file_text],
          file_markdown: quote_check_params[:file_markdown],
          metadata: quote_check_params[:metadata],
          case_id: quotes_case&.id,
          parent_id: quote_check_params[:parent_id],
          source_name: api_user.downcase
        )
        @quote_check = quote_check_service.quote_check

        QuoteFileSecurityScanJob.perform_later(@quote_check.file.id)
        QuoteCheckCheckJob.perform_later(@quote_check.id)

        QuoteCheckMailer.created(@quote_check).deliver_later

        render json: quote_check_json, status: :created
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def update
        quote_check.update!(quote_check_edit_params)

        render json: quote_check_json
      end

      def metadata
        render json: I18n.t("quote_checks.metadata").to_json
      end

      protected

      def quote_check
        @quote_check ||= QuoteCheck
                         .select(*(QuoteCheck.column_names - %w[
                           text anonymised_text
                           file_text file_markdown
                         ]))
                         .eager_load(:file)
                         .select("#{QuoteFile.table_name}.filename")
                         .accessible_for_source(api_user)
                         .find(params[:id])
      end

      def quotes_case
        return unless params[:case_id]

        @quotes_case ||= QuotesCase
                         .select(:id)
                         .accessible_for_source(api_user)
                         .find(params[:case_id])
      end

      def quote_check_json(quote_check_provided = nil)
        QuoteCheckSerializer.new(quote_check_provided || quote_check).as_json
      end

      def quote_check_params
        params.permit(
          :file, :profile,
          :metadata, :parent_id, :reference, :case_id,
          :file_text, :file_markdown
        )
      end

      def quote_check_edit_params
        params.permit(:comment)
      end

      def api_user
        super || "mdso" # TODO: Remove me after no basic auth anymore
      end
    end
  end
end
