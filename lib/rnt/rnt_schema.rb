# frozen_string_literal: true

require "nokogiri"

# Interact with the RNT (Référentiel National des Travaux) data Schema locally.
class RntSchema
  OPENAPI_PATH = Rails.root.join("lib/rnt/mdd_V0.0.3.json").to_s
  VERSION = "0.3"
  XSD_PATH = Rails.root.join("lib/rnt/mdd_V0.0.3.xsd").to_s

  # Validate an XML file against an XSD schema.
  def self.valid?(xml_path, xsd_path = XSD_PATH) # rubocop:disable Metrics/MethodLength
    # Parse XML and XSD
    xml_doc = Nokogiri::XML(File.read(xml_path), &:strict)
    xsd     = Nokogiri::XML::Schema(File.read(xsd_path))

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
end
