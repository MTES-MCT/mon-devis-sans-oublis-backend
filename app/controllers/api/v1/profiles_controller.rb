# frozen_string_literal: true

module Api
  module V1
    # Controller for Profiles API
    class ProfilesController < BaseController
      def index
        profiles = QuoteCheck::PROFILES
        render json: {
          data: profiles,
          options: profiles.map do |profile|
            {
              label: I18n.t("quotes.profile.title.#{profile}"),
              value: profile
            }
          end
        }
      end
    end
  end
end
