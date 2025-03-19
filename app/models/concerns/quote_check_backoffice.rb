# frozen_string_literal: true

# Makes QuoteCheck easier for the Backoffice
module QuoteCheckBackoffice
  extend ActiveSupport::Concern

  class_methods do
    def ransackable_associations(_auth_object = nil)
      [:file]
    end

    def ransackable_attributes(_auth_object = nil)
      %w[
        created_at
        profile
        status

        quote_file_filename

        with_edits
        with_expected_value
        with_file_error
      ]
    end
  end

  def frontend_webapp_url
    return unless id

    profile_path = case profile
                   when "artisan" then "artisan"
                   when "conseiller" then "conseiller"
                   when "mandataire" then "mandataire"
                   when "particulier" then "particulier"
                   else
                     raise NotImplementedError, "Unknown path for profile: #{profile}"
                   end

    URI.join("#{ENV.fetch('FRONTEND_APPLICATION_HOST')}/", "#{profile_path}/", "televersement/", id).to_s
  end
end
