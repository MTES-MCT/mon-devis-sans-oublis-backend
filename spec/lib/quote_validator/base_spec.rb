# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteValidator::Base, type: :service do
  describe ".error_categories" do
    it "returns a hash" do
      expect(described_class.error_categories).to be_a(Hash)
    end

    it "returns error_categories" do
      expect(described_class.error_categories).to include("gestes")
    end
  end

  describe ".error_codes" do
    it "returns a hash" do
      expect(described_class.error_codes).to be_a(Hash)
    end

    it "returns error_codes" do
      expect(described_class.error_codes).to include("rge_manquant", "chauffage_etas_manquant")
    end
  end

  describe ".error_types" do
    it "returns a hash" do
      expect(described_class.error_types).to be_a(Hash)
    end

    it "returns error_types" do
      expect(described_class.error_types).to include("wrong" => "Information erronée")
    end
  end
end
