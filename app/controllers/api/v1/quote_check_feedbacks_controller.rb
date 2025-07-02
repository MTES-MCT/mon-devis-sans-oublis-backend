# frozen_string_literal: true

module Api
  module V1
    # Controller for QuoteCheckFeedbacks API
    class QuoteCheckFeedbacksController < BaseController
      before_action :authorize_internal_mdso_only
      before_action :quote_check
      before_action :validation_error_details, if: -> { params[:validation_error_detail_id].present? }

      def create
        @quote_check_feedback = quote_check.feedbacks.create!(quote_check_feedback_params)

        render json: feedback_json(@quote_check_feedback), status: :created
      end

      protected

      def feedback_json(quote_check_feedback)
        attributes = %w[id quote_check_id comment]

        attributes += if quote_check_feedback.global?
                        %w[rating email] # Global feedback
                      else
                        %w[validation_error_details_id] # Error detail feedback
                      end

        quote_check_feedback.attributes.slice(*attributes)
      end

      def quote_check
        @quote_check ||= QuoteCheck
                         .select(
                           :id,
                           :validation_error_details
                         )
                         .includes(:feedbacks)
                         .accessible_for_source(api_user)
                         .find(params[:quote_check_id])
      end

      def quote_check_feedback_params
        raw_params = params.permit(
          :rating, :email, # Global feedback
          :validation_error_details_id, # Error detail feedback
          :comment
        )
        return raw_params unless defined?(@validation_error_details)

        raw_params.merge(validation_error_details_id: @validation_error_details.fetch("id"))
      end

      def validation_error_details
        # validation_error_detail_id is in singular in path params
        @validation_error_details ||= quote_check.validation_error_details.detect do |details|
          details.fetch("id") == params[:validation_error_detail_id]
        end || raise(ActiveRecord::RecordNotFound,
                     "Couldn't find ValidationErrorDetails with 'id'=#{params[:validation_error_detail_id]}")
      end
    end
  end
end
