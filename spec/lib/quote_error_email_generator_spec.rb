# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteErrorEmailGenerator, type: :service do
  describe ".generate_email_content" do
    let(:quote_check) { create(:quote_check) }

    it "generates email content for a QuoteCheck" do
      expect(described_class.generate_email_content(quote_check)).to include("Aucune erreur à signaler.")
    end
  end

  describe ".generate_case_email_content" do
    let(:quotes_case) { create(:quotes_case) }

    it "generates email content for a QuoteCase" do
      expect(described_class.generate_case_email_content(quotes_case)).to include("Bonjour")
    end
  end

  describe "#html" do
    let(:quote_check) { create(:quote_check) }

    it "returns HTML content for QuoteCheck" do
      generator = described_class.new(quote_check)
      expect(generator.html).to include("Aucune erreur à signaler.")
    end
  end

  describe "#text" do
    let(:quote_check) { create(:quote_check) }

    it "returns Text content for QuoteCheck" do
      generator = described_class.new(quote_check)
      expect(generator.text).to include("Aucune erreur à signaler.")
    end
  end
end
