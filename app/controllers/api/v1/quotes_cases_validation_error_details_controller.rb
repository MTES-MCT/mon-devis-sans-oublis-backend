# frozen_string_literal: true

module Api
  module V1
    # Controller for QuotesCases ValidationErrorDetails API
    class QuotesCasesValidationErrorDetailsController < BaseController
      before_action :authorize_internal_mdso_only, except: :validation_error_detail_deletion_reasons
      before_action :validation_error_details, except: :validation_error_detail_deletion_reasons

      def create
        quotes_case.readd_validation_error_detail!(validation_error_details.fetch("id"))

        head :created
      end

      def update
        quotes_case.comment_validation_error_detail!(
          validation_error_details.fetch("id"),
          validation_error_details_edit_params.fetch(:comment)
        )

        head :ok
      end

      def destroy
        quotes_case.delete_validation_error_detail!(
          validation_error_details.fetch("id"),
          reason: params.fetch(:reason, nil).presence
        )

        head :no_content
      end

      def validation_error_detail_deletion_reasons
        data = QuotesCase::VALIDATION_ERROR_DELETION_REASONS.index_with do # rubocop:disable Style/ItBlockParameter
          I18n.t("validation_error_detail_deletion_reasons.#{it}")
        end

        render json: { data: }
      end

      protected

      def quotes_case
        @quotes_case ||= QuotesCase.find(params[:quotes_case_id])
      end

      def validation_error_details_edit_params
        params.permit(:comment)
      end

      def validation_error_details
        raise ActiveRecord::RecordNotFound, "QuotesCase still in progress" if quotes_case.status == "in_progress"

        @validation_error_details ||= quotes_case.validation_error_details.detect do |error_details|
          error_details.fetch("id") == params[:id]
        end || raise(ActiveRecord::RecordNotFound,
                     "Couldn't find ValidationErrorDetails with 'id'=#{params[:id]}")
      end
    end
  end
end
