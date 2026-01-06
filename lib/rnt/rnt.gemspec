# frozen_string_literal: true

require_relative "lib/rnt/version"

Gem::Specification.new do |spec|
  spec.name          = "rnt"
  spec.version       = Rnt::VERSION
  spec.authors       = ["Nicolas Leger"]
  spec.email         = ["contact@mon-devis-sans-oublis.beta.gouv.fr"]

  spec.summary       = "RNT (Référentiel National des Travaux) Schema library"
  spec.description   = "A Ruby library for interacting with the RNT (Référentiel National des Travaux) data schema locally, providing XML validation and data extraction capabilities via official Web Services." # rubocop:disable Layout/LineLength
  spec.homepage      = "https://gitlab.com/referentiel-numerique-travaux/referentiel-numerique-travaux"

  spec.required_ruby_version = ">= 3.4.0" # rubocop:disable Gemspec/RequiredRubyVersion

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MTES-MCT/mon-devis-sans-oublis-backend/tree/main/lib/rnt"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*",
    "*.xsd",
    "*.json",
    "LICENSE*",
    "README*"
  ]

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "nokogiri", "~> 1.8"
end
