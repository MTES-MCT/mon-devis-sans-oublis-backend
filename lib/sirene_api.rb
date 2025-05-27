# frozen_string_literal: true

require "net/http"

# From form https://www.sirene.fr/sirene/public/recherche
class SireneApi
  # Returns true if the SIRET is known, false otherwise
  def recherche(siret)
    body = Net::HTTP.post(
      URI("https://www.sirene.fr/sirene/public/recherche"),
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

    body.include?("result-left") # TODO: return result including state !body.include?("	Fermé")
  end
end
