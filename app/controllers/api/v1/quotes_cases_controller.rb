# frozen_string_literal: true

module Api
  module V1
    # Controller for QuotesCases API
    class QuotesCasesController < BaseController
      before_action :authorize_request

      before_action :quotes_case, except: %i[create]

      def show
        render json: quotes_case_json
      end

      def create
        @quotes_case = QuotesCase.create!(quotes_case_params)

        render json: quotes_case_json, status: :created
      end

      def update
        quotes_case.update!(quotes_case_edit_params)

        render json: quotes_case_json
      end

      protected

      def quotes_case # rubocop:disable Metrics/MethodLength
        hidable_quote_check_fields = %w[
          text anonymised_text
          file_text file_markdown
        ]

        @quotes_case ||= QuotesCase
                         .eager_load(quote_checks: :feedbacks)
                         .select( # Avoid to load unnecessary heavy fields
                           *QuotesCase.column_names,
                           *(QuoteCheck.column_names - (hidable_quote_check_fields || [])).map do
                             "#{QuoteCheck.table_name}.#{it} AS quote_check_#{it}"
                           end
                         )
                         .accessible_for_source(api_user)
                         .find(params[:id])
      end

      def quotes_case_edit_params
        params.permit(
          :reference
        )
      end

      def quotes_case_json(quotes_case_provided = nil)
        QuotesCaseSerializer.new(quotes_case_provided || quotes_case).as_json
      end

      def quotes_case_params
        params.permit(
          :reference, :profile, :renovation_type, :metadata
        ).merge(
          source_name: api_user.downcase
        )
      end
    end
  end
end
