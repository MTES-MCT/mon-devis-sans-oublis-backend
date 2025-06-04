# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuotesCaseSerializer do
  subject(:serializer) { described_class.new(quotes_case) }

  let(:quotes_case) { create(:quotes_case, reference: "ref") }

  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it "includes id and reference" do
    expect(json).to include(
      "id" => quotes_case.id,
      "reference" => quotes_case.reference
    )
  end

  context "with quote checks" do
    let!(:older_check) { create(:quote_check, case: quotes_case, created_at: 2.days.ago) }
    let!(:newer_check) { create(:quote_check, case: quotes_case, created_at: 1.day.ago) }

    it "includes status" do
      expect(json["status"]).to eq quotes_case.status
    end

    it "includes quote_checks in descending order" do
      expect(json["quote_checks"].map { it["id"] }).to eq [newer_check.id, older_check.id]
    end
  end
end
