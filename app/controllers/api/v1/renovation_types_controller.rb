# frozen_string_literal: true

module Api
  module V1
    # Controller for RenovationTypes API
    class RenovationTypesController < BaseController
      def index
        render json: { data: QuoteCheck::RENOVATION_TYPES }
      end
    end
  end
end
