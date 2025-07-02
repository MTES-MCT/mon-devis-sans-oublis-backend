# frozen_string_literal: true

module Api
  module V1
    # Controller for QuoteChecks ValidationErrorDetails API
    class QuoteChecksValidationErrorDetailsController < BaseController
      before_action :authorize_internal_mdso_only, except: :validation_error_detail_deletion_reasons
      before_action :validation_error_details, except: :validation_error_detail_deletion_reasons

      def create
        quote_check.readd_validation_error_detail!(validation_error_details.fetch("id"))

        head :created
      end

      def update
        quote_check.comment_validation_error_detail!(
          validation_error_details.fetch("id"),
          validation_error_details_edit_params.fetch(:comment)
        )

        head :ok
      end

      def destroy
        quote_check.delete_validation_error_detail!(
          validation_error_details.fetch("id"),
          reason: params.fetch(:reason, nil).presence
        )

        head :no_content
      end

      def validation_error_detail_deletion_reasons
        data = QuoteCheck::VALIDATION_ERROR_DELETION_REASONS.index_with do # rubocop:disable Style/ItBlockParameter
          I18n.t("quote_checks.validation_error_detail_deletion_reasons.#{it}")
        end

        render json: { data: }
      end

      protected

      def quote_check
        @quote_check ||= QuoteCheck
                         .select(*(QuoteCheck.column_names - %w[
                           text anonymised_text
                           file_text file_markdown
                         ]))
                         .accessible_for_source(api_user)
                         .find(params[:quote_check_id])
      end

      def validation_error_details_edit_params
        params.permit(:comment)
      end

      def validation_error_details
        @validation_error_details ||= quote_check.validation_error_details.detect do |error_details|
          error_details.fetch("id") == params[:id]
        end || raise(ActiveRecord::RecordNotFound,
                     "Couldn't find ValidationErrorDetails with 'id'=#{params[:id]}")
      end
    end
  end
end
