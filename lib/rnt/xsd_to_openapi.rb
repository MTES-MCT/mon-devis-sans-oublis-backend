# frozen_string_literal: true

require "nokogiri"
require "yaml"

require "json"
require "pry"

# Simple XSD to OpenAPI YAML converter
class XsdToOpenApi # rubocop:disable Metrics/ClassLength
  OPENAPI_VERSION = "3.0.1"

  def initialize(xsd_path)
    @xsd_path = xsd_path

    @xsd = Nokogiri::XML(File.read(xsd_path))
    @xs = @xsd.root.namespace_definitions.find { it.prefix == "xs" }&.href

    @components = {}
  end

  def convert
    @schema = @xsd.at_xpath("//xs:schema", "xs" => @xs)

    parse_inside_schema
    schema_props
  end
  alias to_yaml convert

  private

  def schema_props # rubocop:disable Metrics/MethodLength
    doc_node = @schema.at_xpath("//xs:annotation/xs:documentation", "xs" => @xs)
    doc_text = doc_node&.text&.strip

    version = doc_text[/Version\s+([^\s-]+)/i, 1] || "1.0.0"
    date = doc_text[/(\d{4}-\d{2}-\d{2})/, 1]
    description = doc_text || "Generated from XSD"

    info = {
      "title" => "#{File.basename(
        @xsd.at_xpath('//xs:schema', 'xs' => @xs)['targetNamespace'] ||
          File.basename(@xsd_path, File.extname(@xsd_path)) ||
          'Schema'
      )} OpenAPI",
      "version" => version,
      "description" => description,
      "x-release-date" => date
    }.compact

    {
      "openapi" => OPENAPI_VERSION,
      "info" => info,
      "paths" => {},
      "components" => {
        "schemas" => @components
      }
    }
  end

  def parse_inside_schema
    @schema.xpath("./xs:complexType | ./xs:element", "xs" => @xs)
           .sort_by { it["name"] == "t_adresse" ? 0 : 1 } # TODO: find first ones to initialize
           .each { @components[it["name"]] = parse_element_or_complex(it) }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def parse_complex_type(node, props: {}, name: nil) # rubocop:disable Metrics/MethodLength
    properties = {}

    name = node["name"] || name

    children = node.element_children.reject { name == "rnt" && it.name.sub("xs:", "") == "attribute" }
    raise NotImplementedError, "parse_complex_type for #{name || node} not implemented" if children.size != 1

    complex_type_node = children.first
    complex_type_name = complex_type_node.name.sub("xs:", "")

    # TODO: Manage xs:attribute
    complex_type_node.xpath("./xs:complexType|./xs:element|./xs:choice/xs:element", "xs" => @xs).each do |el|
      property_name = el["name"] || el["ref"]
      property = parse_element_or_complex(el)
      properties[property_name] = property if property_name
    end

    return { "oneOf" => properties.values } if complex_type_node.element_children.first.name.sub("xs:", "") == "choice"

    props = {
      "type" => "object",
      "properties" => properties,
      "additionalProperties" => false # For LLM
    }.merge(props)

    case complex_type_name
    when "all"
      props["required"] = properties.keys # allOf maybe? like oneOf up-above
    when "sequence"
    # Do nothing, order matters
    else
      raise NotImplementedError, "complex_type_name '#{complex_type_name}' not implemented"
    end

    props
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def complex_type?(node_name)
    case node_name&.gsub("xs:", "")
    when "complexType", "sequence", "all", "choice"
      true
    else
      false
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def parse_element_or_complex(node) # rubocop:disable Metrics/MethodLength
    puts "Parsing node: #{node.name} #{node['name'] || node['ref']}" # rubocop:disable Rails/Output

    props = {}

    name = node["name"]

    ref = node["ref"]
    props["$ref"] = "#/components/schemas/#{ref}" if ref

    raise "Element without name #{node}" unless name || ref

    doc = node.at_xpath("./xs:annotation/xs:documentation", "xs" => @xs)&.text&.strip
    doc = nil if doc&.empty?

    appinfo = node.at_xpath("./xs:annotation/xs:appinfo", "xs" => @xs)&.text&.strip
    appinfo = nil if appinfo&.empty?
    if appinfo
      begin
        parsed_appinfo = JSON.parse(appinfo)
        props["x-appinfo"] = parsed_appinfo
      rescue JSON::ParserError
        props["x-appinfo-raw"] = appinfo
      end
    end

    if complex_type?(node.name)
      return parse_complex_type(node, name:, props:)
    elsif node.name != "element"
      raise NotImplementedError, "Node type '#{node.name}' not implemented"
    end

    children = node.element_children.reject { it.name.gsub("xs:", "") == "annotation" }
    return parse_complex_type(children.first, name:, props:) if children.size == 1 && complex_type?(children.first.name)

    # TODO: minOccurs="0" / maxOccurs="unbounded"
    # TODO: ref like <xs:element ref="donnees_contextuelles"/>

    simple_type = node.at_xpath("./xs:simpleType/xs:restriction", "xs" => @xs)
    node_type = simple_type["base"]&.sub("xs:", "") if simple_type

    if simple_type
      base = simple_type["base"]&.sub("xs:", "") || "string"
      enums = simple_type.xpath("./xs:enumeration", "xs" => @xs).map { it["value"] } # rubocop:disable Rails/Pluck
      props["type"] = map_type(base)
      props["enum"] = enums if enums.any?
    elsif !ref
      props["type"] = map_type(node_type || "string")
    end

    #        <xs:simpleType>
    #                                                             <xs:restriction base="xs:double">
    #                                                                 <xs:minExclusive value="0"/>
    #                                                                 <xs:maxInclusive value="3000000"/>
    #                                                             </xs:restriction>
    #                                                         </xs:simpleType>
    #                                                     </xs:element>
    props["nullable"] = true if node["nillable"] == "true"
    props["description"] = doc if doc

    props.compact

    #   enums = st.xpath('./xs:enumeration', 'xs' => NS).map { |e| e['value'] }
    #   min = st.at_xpath('./xs:minLength', 'xs' => NS)&.[]('value')
    #   max = st.at_xpath('./xs:maxLength', 'xs' => NS)&.[]('value')

    #   prop["enum"] = enums if enums.any?
    #   prop["minLength"] = min.to_i if min
    #   prop["maxLength"] = max.to_i if max
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def map_type(xsd_type)
    case xsd_type
    when "boolean" then "boolean"
    when "date", "string" then "string"
    when "double" then "number"
    when "int", "integer" then "integer"
    else
      raise NotImplementedError, "Type mapping for '#{xsd_type}' not implemented"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  dir = File.dirname(__FILE__)
  openapi_yaml = XsdToOpenApi.new(ARGV[0] || File.expand_path("schema.xsd", dir)).to_yaml
  File.write(ARGV[1] || File.expand_path("schema_openapi.yaml", dir), YAML.dump(openapi_yaml))
  File.write(File.expand_path("schema_openapi.json", dir), JSON.pretty_generate(openapi_yaml))
  puts YAML.dump(openapi_yaml) # rubocop:disable Rails/Output
end
