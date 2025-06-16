# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuotesCasePostCheckMetadata do
  let(:quotes_case) { QuotesCase.new }

  let(:quote_checks_count) { 2 }
  let(:quote_checks) { create_list(:quote_check, quote_checks_count, :finished, case: quotes_case) }

  before do
    quote_checks
  end

  describe "#cost" do
    before do
      quote_checks.last.update!(qa_result: { "usage" => { "completion_tokens" => 10, "prompt_tokens" => 5 } })
    end

    it "returns the sum of quote_check costs" do
      expect(quotes_case.cost).to eq(quote_checks.filter_map(&:cost).sum)
    end
  end

  describe "#finished_at" do
    before do
      quote_checks.last.update!(finished_at: 1.year.from_now)
    end

    it "returns the latest quotes_checks finished_at" do
      expect(quotes_case.finished_at).to eq(quote_checks.last.finished_at)
    end
  end

  describe "#processing_time" do
    before do
      quote_checks.first.update!(started_at: 1.year.ago)
      quote_checks.last.update!(finished_at: 1.year.from_now)
    end

    it "returns the difference between the latest finished_at and the earliest started_at" do
      expect(quotes_case.processing_time).to be_within(2.days).of(2.years)
    end
  end

  describe "#started_at" do
    before do
      quote_checks.first.update!(started_at: 1.year.ago)
    end

    it "returns the earliest quotes_checks started_at" do
      expect(quotes_case.started_at).to eq(quote_checks.first.started_at)
    end
  end

  describe "#status" do
    before do
      quote_checks.first.update!(finished_at: nil)
      quote_checks.last.update!(validation_errors: ["error"])
    end

    it "returns 'pending' if any quote_check is pending" do
      expect(quotes_case.status).to eq("pending")
    end

    context "when all quote_checks are valid" do
      before do
        quote_checks.each { it.update!(finished_at: Time.current) }
      end

      it "returns 'valid'" do
        expect(quotes_case.status).to eq("valid")
      end
    end
  end
end
