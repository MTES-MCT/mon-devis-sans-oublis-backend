# frozen_string_literal: true

require "nokogiri"

require_relative "../../lib/rnt/rnt_schema"

# Service to validate a QuoteCheck against the RNT (Référentiel National des Travaux)
class RntValidatorService
  class NotProcessableError < StandardError; end

  attr_reader :quote_check_id

  def initialize(quote_check_id)
    @quote_check_id = quote_check_id
  end

  # Complete the RNT JSON with required donnees_contextuelles
  def self.complete_json_for_rnt(json, aide_financiere_collection:)
    json.merge(
      "donnees_contextuelles" => {
        "version" => RntSchema::VERSION,
        "contexte" => "devis",
        "usage_batiment" => "appartement_chauffage_individuel", # TODO: Remove me when optional
        "aide_financiere_collection" => Array.wrap(aide_financiere_collection)
      }.merge(json["donnees_contextuelles"] || {})
    )
  end

  def self.rnt_validable?(quote_check)
    quote_check.anonymized_text.present?
  end

  def self.rnt_json_to_xml(json, aide_financiere_collection:)
    rnt_xsd_schema = File.read(RntSchema::XSD_PATH)
    json_to_xml_prompt = "Transforme le JSON suivant en XML conforme au schéma du RNT (Référentiel National des Travaux) fourni. Le XML doit être strictement conforme au schéma XSD du RNT. #{rnt_xsd_schema} Ne pas ajouter d'éléments ou d'attributs non définis dans le schéma. Voici le JSON :" # rubocop:disable Layout/LineLength
    Llms::Albert.new(
      json_to_xml_prompt,
      result_format: :xml
    ).chat_completion(
      complete_json_for_rnt(json, aide_financiere_collection:)
    )
  end

  def self.rnt_json_for_text(text)
    # Option A: Using full RNT Schema directly

    # rnt_json_schema ||= JsonOpenapi.make_schema_refs_inline!(
    #   JSON.parse(File.read(RntSchema::OPENAPI_PATH))
    # ).dig("components", "schemas", "rnt")

    # json_prompt = "Retrouver les informations du RNT (Référentiel National des Travaux) dans le texte de devis suivant." # rubocop:disable Layout/LineLength

    # Llms::Albert.new(
    #   json_prompt,
    #   json_schema: rnt_json_schema,
    #   result_format: :json
    # ).chat_completion(text)

    # Option B: Using only the relevant subset of the RNT Schema for Works (travaux)
    prompt = Rails.root.join("lib/rnt/rnt_works_data_prompts/global.txt").read
    travaux_json = Llms::Mistral.new(prompt, result_format: :json).chat_completion(text)
    {
      "projet_travaux" => {
        "travaux_collection" => {
          "travaux" => travaux_json.fetch(:travaux, travaux_json.fetch("travaux"))
        }
      }
    }
  end

  # Validate the QuoteCheck and return a hash with:
  # - :quote_check_rnt_json => The extracted RNT data in JSON format
  # - :quote_check_rnt_xml => The extracted RNT data in XML format
  # - :rnt_validation_response => The response from the RNT validation service
  def validate # rubocop:disable Metrics/MethodLength
    unless self.class.rnt_validable?(quote_check)
      raise NotProcessableError,
            "QuoteCheck is not processable because not anonymized yet."
    end

    # Steps:
    # 1. Use LLM to extract RNT data from QuoteCheck anonymized_text in JSON format
    quote_check_rnt_json = self.class.rnt_json_for_text(quote_check.anonymized_text)
    # 2. Convert JSON to RNT XML format using LLM
    quote_check_rnt_xml = self.class.rnt_json_to_xml(
      quote_check_rnt_json,
      aide_financiere_collection: quote_check.renovation_type == "ampleur" ? "mpr_ampleur" : "mpr_geste"
    )
    # 3. Validate XML against RNT schema using RNT Web service
    rnt_validation_response = Rnt.new.validate(quote_check_rnt_xml)

    {
      quote_check_rnt_json:,
      quote_check_rnt_xml:,
      rnt_validation_response:
    }
  end

  private

  def quote_check
    @quote_check ||= QuoteCheck.find(quote_check_id)
  end
end
