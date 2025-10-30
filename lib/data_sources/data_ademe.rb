# frozen_string_literal: true

require "net/http"

# Now on Data.gouv https://www.data.gouv.fr/fr/dataservices/api-professionnels-rge/
class DataAdeme
  class ServiceUnavailableError < StandardError; end

  # TODO: use API Entreprise https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Certifications-professionnelles/paths/~1v3~1ademe~1etablissements~1%7Bsiret%7D~1certification_rge/get
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
  # rubocop:disable Metrics/CyclomaticComplexity
  def historique_rge(params) # rubocop:disable Metrics/MethodLength
    uri ||= params[:uri] || historique_rge_uri(params)
    parsed_uri = URI(uri)

    http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
    http.use_ssl = true
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch("ADEME_SKIP_SSL_VERIFICATION", nil))
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Get.new(parsed_uri.request_uri)
    response = http.request(request)
    body = response.body

    raise ServiceUnavailableError if body.include?("all shards failed")
    raise ServiceUnavailableError, uri if body.include?("Impossible d'effectuer cette")

    json = JSON.parse(body)
    result = json.merge(
      "results" => fix_results_schema(json["results"])
    )
    return result if !result.key?("next") || result["next"].blank?

    next_result = historique_rge(uri: result.fetch("next"))
    result.merge(
      "next" => next_result["next"],
      "results" => result["results"] + next_result.fetch("results")
    )
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  private

  def fix_results_schema(results)
    # Since 2025-10-03 Schema update, the "domaine" field is supposed to be an Array
    # See https://data.ademe.fr/datasets/historique-rge
    # But the related API might still return single String value instead of Array
    results&.map do |result|
      result.merge(
        "domaine" => Array.wrap(result["domaine"]), # Ensure Array as in schema
        # Remove empty "http://" value that not match the Regex in documentation
        "site_internet" => result["site_internet"]&.gsub(%r{https?://$}i, "")&.strip,
        "telephone" => format_phone(result["telephone"])
      )
    end
  end

  # format_phone("76653196X") => "07 66 53 19 6X"
  # So it matches the Regex in documentation
  def format_phone(phone)
    phone = "0#{phone}" if phone&.scan(/\d/)&.length == 9 # Add leading 0 if missing

    phone.scan(/\d{1,2}/).join(" ")
  end
end
