# frozen_string_literal: true

require "net/http"

# Previously called "recensement des professionnels RGE (Reconnu Garant de l'Environnement)"
# Now on Data.gouv https://www.data.gouv.fr/fr/dataservices/api-professionnels-rge/
class DataAdeme
  class ServiceUnavailableError < StandardError; end

  # params: hash
  #   - qs: query string
  #   like "siret=12345678900000"
  #   or siret:%12345678900000 AND date_debut:[* TO 2023-01-13] AND date_fin:[2023-01-13 TO *]&
  def historique_rge(params)
    uri = "https://data.ademe.fr/data-fair/api/v1/datasets/historique-rge/lines?#{params.compact.to_query}"
    body = Net::HTTP.get(URI(uri))

    raise ServiceUnavailableError if body.include?("all shards failed")
    raise ServiceUnavailableError, uri if body.include?("Impossible d'effectuer cette")

    # New version is not working https://data.ademe.fr/datasets/liste-des-entreprises-rge-2
    # Example: https://data.ademe.fr/data-fair/api/v1/datasets/liste-des-entreprises-rge-2/lines?page=1&after=1&size=12&sort=nom_entreprise&select=siret,nom_entreprise,adresse,code_postal,commune,latitude,longitude,telephone,email,site_internet,code_qualification,nom_qualification,url_qualification,nom_certificat,domaine,meta_domaine,organisme,particulier,_file.content,_file.content_type,_file.content_length,_attachment_url,_geopoint,_id,_i,_rand&format=json&q=12345678900000&q_mode=simple
    JSON.parse(body)
  end
end
