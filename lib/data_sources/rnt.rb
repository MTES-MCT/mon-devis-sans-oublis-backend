# frozen_string_literal: true

require "json"

# Interact with the RNT XML Web Service (Référentiel National des Travaux).
class Rnt
  HOST = ENV.fetch("RNT_HOST", "https://rnt-validation.dimn-cstb.fr/")

  # rubocop:disable Metrics/AbcSize
  def validate(xml) # rubocop:disable Metrics/MethodLength
    request = Net::HTTP::Post.new("/validation")
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/xml"
    request.body = xml

    options = { use_ssl: true }
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch(
                                             "RNT_SKIP_SSL_VERIFICATION", nil
                                           ))
      options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
    end

    response = Net::HTTP.start(
      URI(HOST).host,
      URI(HOST).port,
      **options
    ) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    response.body
  end
  # rubocop:enable Metrics/AbcSize
end
