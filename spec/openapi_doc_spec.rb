# frozen_string_literal: true

require "openapi3_parser"
require "rails_helper"

describe "OpenAPI Documentation" do # rubocop:disable RSpec/DescribeClass
  let(:document) { Openapi3Parser.load_file(spec_filepath) }

  context "with Internal API v1" do
    let(:spec_filepath) do
      Rails.root.join("swagger", "v1", Rails.application.config.openapi_file.call("v1", "internal"))
    end

    it "has a valid OpenAPI schema" do
      expect(document).to be_valid, "OpenAPI schema is invalid:\n#{document.errors.map do |error|
        [error.context, error.message].join(' : ')
      end.join("\n")}"
    end
  end

  context "with Partner API v1" do
    let(:spec_filepath) do
      Rails.root.join("swagger", "v1", Rails.application.config.openapi_file.call("v1", "partner"))
    end

    it "has a valid OpenAPI schema" do
      expect(document).to be_valid, "OpenAPI schema is invalid:\n#{document.errors.map do |error|
        [error.context, error.message].join(' : ')
      end.join("\n")}"
    end

    it "includes Auth API paths" do
      expect(document.paths.find("/auth/check")).not_to be_nil
    end
  end
end
