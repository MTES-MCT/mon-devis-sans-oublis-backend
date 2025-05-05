# frozen_string_literal: true

module Api
  module V1
    # Controller for QuotesCases API
    class QuotesCasesController < BaseController
      before_action :authorize_request

      def create
        @quotes_case = QuotesCase.create!(quotes_case_params)

        render json: quotes_case_json, status: :created
      end

      protected

      def quotes_case
        @quotes_case ||= QuotesCase
                         .accessible_for_source(api_user)
                         .find(params[:id])
      end

      def quotes_case_json(quotes_case_provided = nil)
        QuotesCaseSerializer.new(quotes_case_provided || quotes_case).as_json
      end

      def quotes_case_params
        params.permit(
          :reference
        )
      end
    end
  end
end
