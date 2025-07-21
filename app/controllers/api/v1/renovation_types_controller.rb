# frozen_string_literal: true

module Api
  module V1
    # Controller for RenovationTypes API
    class RenovationTypesController < BaseController
      def index
        renovation_types = QuoteCheck::RENOVATION_TYPES
        render json: {
          data: renovation_types,
          options: renovation_types.map do |renovation_type|
            {
              label: I18n.t("quotes.renovation_type.title.#{renovation_type}"),
              value: renovation_type
            }
          end
        }
      end
    end
  end
end
