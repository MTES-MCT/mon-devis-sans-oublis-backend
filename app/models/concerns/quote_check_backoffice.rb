# frozen_string_literal: true

# Makes QuoteCheck easier for the Backoffice
module QuoteCheckBackoffice
  extend ActiveSupport::Concern

  class_methods do
    def ransackable_associations(_auth_object = nil)
      [:file]
    end

    def ransackable_attributes(_auth_object = nil) # rubocop:disable Metrics/MethodLength
      %w[
        status
        created_at

        source_name
        reference
        profile
        renovation_type

        quote_file_filename

        ocrable
        non_ocred
        ocred

        with_edits
        with_expected_value
        with_feedback_email
        with_file_error
        with_file_type_error
        with_price_error
      ]
    end
  end

  included do
    attr_accessor :process_synchronously
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
