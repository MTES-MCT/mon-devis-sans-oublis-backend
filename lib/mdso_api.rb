# frozen_string_literal: true

require "committee"

# This class is responsible for validating the response from the MDSO API
class MdsoApi
  class InvalidResponse < Committee::InvalidResponse; end

  attr_reader :schema_path, :version

  def initialize(section = "partner", version = "v1")
    @version = version
    @schema_path = Rails.root.join("swagger", version, "mon-devis-sans-oublis_api_v1_#{section}_swagger.yaml")

    raise ArgumentError, "Invalid schema path" unless File.exist?(schema_path)
  end

  def validate_quote_check!(quote_check_hash)
    path = "/quote_checks"
    method = "post"

    data_hash = quote_check_hash
    status_code = 201
    validate_response(path, method, data_hash, status_code)
  end

  protected

  # rubocop:disable Metrics/MethodLength
  def validate_response(path, method, data_hash, status_code = 200) # rubocop:disable Naming/PredicateMethod
    strict = true
    schema = Committee::Drivers.load_from_file(schema_path, parser_options: { strict_reference_validation: strict })

    request_operation = schema.open_api.request_operation(method, path)

    headers = { "Content-Type" => "application/json" }
    response_body = OpenAPIParser::RequestOperation::ValidatableResponseBody.new(
      status_code, data_hash, headers
    )

    check_header = true
    validator_options = {}
    begin
      request_operation.validate_response_body(
        response_body,
        response_validate_options(strict, check_header, validator_options: validator_options)
      )
    rescue OpenAPIParser::OpenAPIError => e
      raise InvalidResponse.new(e.message, original_error: e)
    end

    true
  end
  # rubocop:enable Metrics/MethodLength

  private

  def response_validate_options(strict, check_header, validator_options: {})
    options = { strict: strict, validate_header: check_header }

    if OpenAPIParser::SchemaValidator::ResponseValidateOptions.method_defined?(:validator_options)
      ::OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(**options, **validator_options)
    else
      ::OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(**options)
    end
  end
end
