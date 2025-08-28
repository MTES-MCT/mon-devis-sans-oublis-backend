# frozen_string_literal: true

require "net/http"

# Now on Data.gouv https://www.data.gouv.fr/fr/dataservices/api-professionnels-rge/
class DataAdeme
  class ServiceUnavailableError < StandardError; end

  API_HOST = "https://data.ademe.fr/data-fair/api/v1"

  def self.rge_openapi_uri
    "#{API_HOST}/datasets/liste-des-entreprises-rge-2/api-docs.json" # V1 does not have OpenAPI schema
  end

  # params: hash
  #   - qs: query string
  #   like "siret=12345678900000"
  #   or siret:%12345678900000 AND date_debut:[* TO 2023-01-13] AND date_fin:[2023-01-13 TO *]&
  def historique_rge_uri(params)
    # Using V1 https://data.ademe.fr/datasets/historique-rge
    "#{API_HOST}/datasets/historique-rge/lines?#{params.compact.to_query}"

    # New version V2 is not working https://data.ademe.fr/datasets/liste-des-entreprises-rge-2
    # Example: https://data.ademe.fr/data-fair/api/v1/datasets/liste-des-entreprises-rge-2/lines?page=1&after=1&size=12&sort=nom_entreprise&select=siret,nom_entreprise,adresse,code_postal,commune,latitude,longitude,telephone,email,site_internet,code_qualification,nom_qualification,url_qualification,nom_certificat,domaine,meta_domaine,organisme,particulier,_file.content,_file.content_type,_file.content_length,_attachment_url,_geopoint,_id,_i,_rand&format=json&q=12345678900000&q_mode=simple
  end

  # Use params to build the URI or force URI (for direct next pages)
  # rubocop:disable Metrics/AbcSize
  def historique_rge(params) # rubocop:disable Metrics/MethodLength
    uri ||= params[:uri] || historique_rge_uri(params)
    body = Net::HTTP.get(URI(uri))

    raise ServiceUnavailableError if body.include?("all shards failed")
    raise ServiceUnavailableError, uri if body.include?("Impossible d'effectuer cette")

    json = JSON.parse(body)
    return json if !json.key?("next") || json["next"].blank?

    next_json = historique_rge(uri: json.fetch("next"))
    json.merge(
      "next" => next_json["next"],
      "results" => json["results"] + next_json.fetch("results")
    )
  end
  # rubocop:enable Metrics/AbcSize
end
