# frozen_string_literal: true

require "json"

# Interact with the RNT XML Web Service (Référentiel National des Travaux).
class Rnt
  HOST = ENV.fetch("RNT_HOST", "https://rnt-validation.dimn-cstb.fr/")

  def validate(xml)
    request = Net::HTTP::Post.new("/validation")
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/xml"
    request.body = xml

    response = Net::HTTP.start(URI(HOST).host, URI(HOST).port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    response.body
  end
end
