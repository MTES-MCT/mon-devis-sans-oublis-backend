# frozen_string_literal: true

require "nokogiri"

require_relative "../../lib/rnt/rnt_schema"

# Service to validate a QuoteCheck against the RNT (Référentiel National des Travaux)
class RntValidatorService # rubocop:disable Metrics/ClassLength
  class NotProcessableError < StandardError; end

  attr_reader :quote_check_id, :rnt_check

  def initialize(quote_check_id)
    @quote_check_id = quote_check_id
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.clean_xml_for_rnt(xml_for_rnt) # rubocop:disable Metrics/MethodLength
    doc = Nokogiri::XML(xml_for_rnt)

    # Remove inner projet_travaux > projet_travaux wrapper node
    doc.xpath("/rnt/projet_travaux/projet_travaux").each do |inner_node|
      parent_node = inner_node.parent
      inner_node.children.each { parent_node.add_child(it) }
      inner_node.remove
    end

    # Remove all empty nodes
    doc.xpath("//*[not(node())]").each(&:remove)

    # Remove usage_systeme nodes if not relevant
    doc.xpath("//usage_systeme").each do |node|
      parent_lot_travaux = node.parent.at_xpath("lot_travaux")&.text
      node.remove unless parent_lot_travaux.match?(/systeme/i)
    end

    schema_version = doc.root["version"]
    rnt_version = doc.at_xpath("/rnt/projet_travaux/donnees_contextuelles/version")&.text&.strip
    rnt_schema = RntSchema.new(rnt_version:, schema_version:)

    # Ensure float for percentage
    elements_in_percentage = rnt_schema.elements_in_percentage
    elements_in_percentage.each do |field_name|
      doc.xpath("//#{field_name}").each do |node|
        value = node.text.strip

        numeric_value = Float(value.chomp("%"))
        numeric_value /= 100.0 if numeric_value > 100
        node.content = numeric_value.to_s
      end
    end

    element_names_with_sources = rnt_schema.element_names_with_sources
    doc.xpath("//*").each do |elt|
      # Remove elements that are not expected in RNT XML
      unless element_names_with_sources.key?(elt.name)
        elt.remove
        next
      end

      # Check sources of elements and remove those not in the XSD
      sources = element_names_with_sources.fetch(elt.name)
      elt.remove if sources&.none? { rnt_schema.matching_path?(elt.path, it) }
    end

    # Add reference_travaux to each travaux if missing (required by RNT XSD)
    doc.xpath("//travaux").each_with_index do |travaux_node, index|
      reference_travaux_node = travaux_node.at_xpath("reference_travaux")
      next if reference_travaux_node

      type_travaux_node = travaux_node.at_xpath("type_travaux")
      reference_travaux_value = type_travaux_node ? type_travaux_node.text.strip : "unknown"
      new_node = Nokogiri::XML::Node.new("reference_travaux", doc)
      new_node.content = "travaux-#{index + 1}-#{reference_travaux_value}"
      travaux_node.add_child(new_node)
    end

    doc.to_xml
       .lines.reject { |line| line.strip.empty? }.join # Remove empty lines
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Complete the RNT JSON with required donnees_contextuelles
  def self.complete_json_for_rnt(json, aide_financiere_collection:, rnt_version:) # rubocop:disable Metrics/MethodLength
    projet_travaux = json["projet_travaux"]

    unless projet_travaux
      return complete_json_for_rnt(
        { "projet_travaux" => json },
        aide_financiere_collection:, rnt_version:
      )
    end

    json.merge(
      "projet_travaux" => projet_travaux.merge(
        {
          "donnees_contextuelles" => {
            "version" => rnt_version,
            "contexte" => "devis",
            "aide_financiere_collection" => Array.wrap(aide_financiere_collection)
          }.merge(projet_travaux["donnees_contextuelles"] || {})
        }
      )
    )
  end

  def self.rnt_validable?(quote_check)
    quote_check.anonymized_text.present?
  end

  def self.rnt_json_to_xml(json, aide_financiere_collection:) # rubocop:disable Metrics/MethodLength
    rnt_schema = RntSchema.new

    rnt_xsd_schema = File.read(rnt_schema.xsd_path)
    json_to_xml_prompt = "Transforme le JSON suivant en XML conforme au schéma du RNT (Référentiel National des Travaux) fourni. Le XML doit être strictement conforme au schéma XSD du RNT. #{rnt_xsd_schema} Ne pas ajouter d'éléments ou d'attributs non définis dans le schéma. Voici le JSON :" # rubocop:disable Layout/LineLength
    llm_call = Llms::Albert.new( # Mistral still render JSON instead of XML
      json_to_xml_prompt,
      result_format: :xml,

      xml_root_name: "rnt",
      xml_root_attrs: { version: rnt_schema.schema_version }
    )

    xml_for_rnt = llm_call.chat_completion(
      complete_json_for_rnt(json, aide_financiere_collection:, rnt_version: rnt_schema.rnt_version)
    )
    clean_xml_for_rnt(xml_for_rnt)
  end

  def self.rnt_json_for_text(text)
    # Option A: Using full RNT Schema directly

    # rnt_json_schema ||= JsonOpenapi.make_schema_refs_inline!(
    #   JSON.parse(File.read(RntSchemanew.openapi_path))
    # ).dig("components", "schemas", "rnt")

    # json_prompt = "Retrouver les informations du RNT (Référentiel National des Travaux) dans le texte de devis suivant." # rubocop:disable Layout/LineLength

    # Llms::Albert.new(
    #   json_prompt,
    #   json_schema: rnt_json_schema,
    #   result_format: :json
    # ).chat_completion(text).deep_transform_keys(&:to_s)

    # Option B: Using only the relevant subset of the RNT Schema for Works (travaux)
    prompt = Rails.root.join("lib/rnt/rnt_works_data_prompts/global.txt").read
    travaux_json = Llms::Mistral.new(prompt, result_format: :json).chat_completion(text)
    {
      "projet_travaux" => {
        "travaux_collection" => {
          "travaux" => travaux_json.fetch(:travaux, travaux_json["travaux"])
        }
      }
    }.deep_transform_keys(&:to_s)
  end

  # Validate the QuoteCheck and return a hash with:
  # - :quote_check_rnt_json => The extracted RNT data in JSON format
  # - :quote_check_rnt_xml => The extracted RNT data in XML format
  # - :rnt_validation_response => The response from the RNT validation service
  # rubocop:disable Metrics/AbcSize
  def validate # rubocop:disable Metrics/MethodLength
    @rnt_check = nil

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
    @rnt_check = RntCheck.create!(quote_check:, sent_input_xml: quote_check_rnt_xml, sent_at: Time.current)
    rnt_validation_response = Rnt.new.validate(quote_check_rnt_xml)
    @rnt_check.update!(
      result_json: rnt_validation_response,
      result_at: Time.current
    )

    {
      quote_check_rnt_json:,
      quote_check_rnt_xml:,
      rnt_validation_response:
    }
  end
  # rubocop:enable Metrics/AbcSize

  private

  def quote_check
    @quote_check ||= QuoteCheck.find(quote_check_id)
  end
end
