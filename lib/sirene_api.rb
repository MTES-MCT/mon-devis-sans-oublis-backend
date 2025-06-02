# frozen_string_literal: true

require "net/http"

# From form https://www.sirene.fr/sirene/public/recherche
class SireneApi
  # Returns true if the SIRET is known, false otherwise
  def recherche(siret) # rubocop:disable Metrics/MethodLength
    body = Net::HTTP.start(
      "www.sirene.fr", 443,
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    ) do |http|
      http.post(
        "/sirene/public/recherche",
        URI.encode_www_form(
          "recherche.sirenSiret" => siret
          # "recherche.raisonSociale" => "",
          # "recherche.adresse" => "",
          # "recherche.commune" => "",
          # "recherche.excludeClosed" => "true",
          # "__checkbox_recherche.excludeClosed" => "true",
          # "recherche.captcha" => ""
        ),
        "Content-Type" => "application/x-www-form-urlencoded"
      ).body
    end

    body.include?("result-left") # TODO: return result including state !body.include?("	Fermé")
  end
end
