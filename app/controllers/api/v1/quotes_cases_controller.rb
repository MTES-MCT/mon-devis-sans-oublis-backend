# frozen_string_literal: true

module Api
  module V1
    # Controller for QuotesCases API
    class QuotesCasesController < BaseController
      before_action :authorize_request, except: :email_content
      before_action :authorize_internal_mdso_only, only: :email_content

      before_action :quotes_case, except: %i[create]

      def show
        # Update result_sent_at for all quote_checks in this case
        quotes_case.quote_checks.each { |qc| update_result_sent_at(qc) }
        render json: quotes_case_json
      end

      def email_content
        render html: QuoteErrorEmailGenerator.generate_case_email_content(quotes_case).html_safe
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
          text anonymized_text
          file_text file_markdown
        ]

        @quotes_case ||= QuotesCase
                         .left_joins(quote_checks: %i[feedbacks file])
                         .select( # Avoid to load unnecessary heavy fields
                           *QuotesCase.column_names,
                           *(QuoteCheck.column_names - (hidable_quote_check_fields || [])).map do # rubocop:disable Style/ItBlockParameter
                             "#{QuoteCheck.table_name}.#{it} AS quote_check_#{it}"
                           end,
                           %w[filename].map { "#{QuoteFile.table_name}.#{it}" }
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

      def update_result_sent_at(quote_check)
        return if quote_check.result_sent_at.present?
        return if quote_check.status == "pending"

        quote_check.update_column(:result_sent_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
