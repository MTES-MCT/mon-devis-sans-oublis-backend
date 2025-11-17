# frozen_string_literal: true

require "nokogiri"

# Interact with the RNT (Référentiel National des Travaux) data Schema locally.
class RntSchema
  OPENAPI_PATH = Rails.root.join("lib/rnt/mdd_v0.0.3.json").to_s
  # See versions on https://gitlab.com/referentiel-numerique-travaux/referentiel-numerique-travaux/-/blob/main/versions.yml
  VERSION = "0.3" # full RNT version for the Web Service, not only the Schema version
  XSD_PATH = Rails.root.join("lib/rnt/mdd_v0.0.3.xsd").to_s

  attr_reader :xsd_path

  def initialize(xsd_path = XSD_PATH)
    @xsd_path = xsd_path
  end

  def types_travaux
    enum_info(xsd.at_xpath("//xs:element[@name='type_travaux']"))
  end

  def caracteristiques_travaux(type_travaux)
    xsd_type_travaux = xsd.at_xpath("//xs:element[@name='#{type_travaux}']")
    return {} unless xsd_type_travaux

    xsd_type_travaux.xpath("./xs:complexType/xs:all/xs:element").to_h do |element|
      [element["name"], extract_elt_attributes(element)]
    end
  end

  def extract_elt_attributes(element) # rubocop:disable Metrics/MethodLength
    has_enum = element.at_xpath(".//xs:simpleType/xs:restriction/xs:enumeration").present?
    type = if has_enum
             "enum"
           else
             (element["type"] || element.at_xpath("./xs:simpleType/xs:restriction")["base"]).split(":").last
           end

    {
      type:,
      description: element.at_xpath("xs:annotation/xs:documentation")&.text&.strip,
      # TODO: we can manage minOccurs, maxOccurs, minExclusive, maxExclusive, pattern...
      enum: type == "enum" ? enum_info(element) : nil
    }.compact
  end

  # rubocop:disable Metrics/AbcSize
  def prompt_travaux(type = nil, description = nil) # rubocop:disable Metrics/MethodLength
    unless type
      types_travaux_infos = types_travaux

      return <<~PROMPT
                Contexte : Nous avons reçu un devis de rénovation énergétique d'un artisan pour un particulier. Nous avons anonymisé son texte et nous souhaitons récupérer les travaux de rénovation énergétique avec leurs critères techniques. Il peut y avoir plusieurs travaux de travaux.#{' '}

                Rôle : Vous êtes un expert en lecture de devis et vous devez récupérer les données structurées pour les intégrer dans le JSON suivant


                # Liste des types de travaux pertinents
                travaux_pertinents = [#{types_travaux_infos.keys.map { "\"#{it}\"" }.join(', ')}]


                Voici les JSON que l'on souhaite récupérer :#{' '}

        # JSON général

        ```jsx
        {
        travaux : [{travaux1},{travaux2}...]
        }#{' '}
        ```

                #{types_travaux_infos.map do |sub_type, sub_description|
                  prompt_travaux(sub_type, sub_description)
                end.join("\n\n")}
      PROMPT
    end

    caracteristiques = caracteristiques_travaux(type)
    <<~PROMPT
      ### #{description ? "#{description} (#{type})" : type} :

      ```jsx
      {
      #{caracteristiques.map do |name, attrs|
        enum = attrs[:enum] ? "(#{attrs[:enum].keys.join(',')})" : ''

        "#{name}: #{attrs[:type]}#{enum}, #{attrs[:description]};"
      end.join("\n")}
      }
      ```
    PROMPT
  end
  # rubocop:enable Metrics/AbcSize

  def valid?(xml_path)
    # Parse XML and XSD
    xml_doc = Nokogiri::XML(File.read(xml_path), &:strict)

    # Run validation
    errors = xsd.validate(xml_doc)
    if errors.empty?
      Rails.logger.debug "✅ XML is valid against schema"
      true
    else
      Rails.logger.debug "❌ XML failed validation:"
      errors.each { |e| Rails.logger.debug " - #{e.message} (line #{e.line})" }
      false
    end
  end

  def xsd
    @xsd ||= Nokogiri::XML(File.read(xsd_path))
  end

  def xsd_schema
    @xsd_schema ||= Nokogiri::XML::Schema(File.read(xsd_path))
  end

  private

  def enum_info(enumeration_xpath)
    enum_descriptions = JSON.parse(enumeration_xpath.at_xpath("xs:annotation/xs:appinfo")&.text&.strip)

    enumeration_xpath.xpath(".//xs:simpleType/xs:restriction/xs:enumeration/@value")
                     .map(&:value).index_with { enum_descriptions[it] }
  end
end
