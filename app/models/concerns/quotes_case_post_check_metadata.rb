# frozen_string_literal: true

# Add post case data
module QuotesCasePostCheckMetadata
  extend ActiveSupport::Concern

  included do
    STATUSES = QuoteCheck::STATUSES # rubocop:disable Lint/ConstantDefinitionInBlock
  end

  # Returns a float number in €
  def cost
    return unless quote_checks.any?

    quote_checks.filter_map(&:cost).sum
  end

  def processing_time
    return unless finished_at

    finished_at - started_at
  end

  # valid? is already used by the framework
  def quotes_case_valid?
    status == "valid"
  end

  def started_at
    quote_checks.minimum(:started_at)
  end

  def finished_at
    read_attribute(:finished_at) ||
      quote_checks.maximum(:finished_at)
  end

  def frontend_webapp_url(mtm_campaign: nil) # rubocop:disable Metrics/MethodLength
    return unless id

    profile_path = case profile
                   when "artisan" then "artisan"
                   when "conseiller", "email" then "conseiller"
                   when "mandataire" then "mandataire"
                   when "particulier" then "particulier"
                   else
                     raise NotImplementedError, "Unknown path for profile: #{profile}"
                   end

    uri = URI.join("#{ENV.fetch('FRONTEND_APPLICATION_HOST')}/", "#{profile_path}/", "dossier/", id)
    uri.query = URI.encode_www_form(mtm_campaign:) if mtm_campaign
    uri.to_s
  end

  # pending if any quote_check is pending
  # valid if all quote_checks are valid
  # else invalid
  def status
    return unless quote_checks.any?

    return "pending" if quote_checks.any? { it.status == "pending" } ||
                        finished_at.nil?

    quote_checks.all?(&:quote_valid?) ? "valid" : "invalid"
  end
end
