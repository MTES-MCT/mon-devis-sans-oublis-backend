# frozen_string_literal: true

require "rails_helper"

RSpec.describe UriExtended, type: :service do
  describe ".host_with_port" do
    context "with HTTPS secure" do
      let(:url) { "https://example.com" }

      it "returns the host" do
        expect(described_class.host_with_port(url)).to eq("example.com")
      end
    end

    context "with localhost with port" do
      let(:url) { "http://localhost:3000" }

      it "returns the host and port if provided" do
        expect(described_class.host_with_port(url)).to eq("localhost:3000")
      end
    end
  end
end
