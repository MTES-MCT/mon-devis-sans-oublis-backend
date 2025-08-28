# frozen_string_literal: true

require "rails_helper"

RSpec.describe Fiability, type: :service do
  describe ".count_differences" do
    context "with missing values" do
      it "counts as difference" do
        expect(described_class.count_differences(
                 ["a"],
                 %w[a b c]
               )).to eq(2)
      end
    end

    context "with mixed changes" do
      it "counts the differences" do
        expect(described_class.count_differences(
                 %w[a c d],
                 %w[a b c d e]
               )).to eq(2)
      end
    end
  end
end
