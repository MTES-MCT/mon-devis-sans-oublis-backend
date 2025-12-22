# frozen_string_literal: true

require "json"

require "nokogiri"

# Utility class to convert JSON to XML
class JsonToXml
  def self.build_xml_from_hash(xml, data)
    case data
    when Hash
      data.each do |key, value|
        xml.send(key) { build_xml_from_hash(xml, value) }
      end
    when Array
      data.each { build_xml_from_hash(xml, it) }
    else
      xml.text(data.to_s)
    end
  end

  def self.convert(json_string, options = {})
    root_name = options[:root_name] || "root"
    root_attrs = options[:root_attrs] || {}

    data = JSON.parse(json_string)
    data = data.fetch(root_name) if root_name && data.is_a?(Hash) && data.key?(root_name)

    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.send(root_name, root_attrs) do
        build_xml_from_hash(xml, data)
      end
    end

    builder.to_xml
  end
end
