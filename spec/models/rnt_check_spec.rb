# frozen_string_literal: true

require "rails_helper"

RSpec.describe RntCheck do
  describe "#rnt_version" do
    it "extracts the RNT version from the sent_input_xml" do # rubocop:disable RSpec/ExampleLength
      rnt_check = described_class.new(
        sent_input_xml: <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <rnt version="0.4">
            <some_data></some_data>
          </rnt>
        XML
      )
      expect(rnt_check.rnt_version).to eq("0.4")
    end
  end

  describe "#schema_version" do
    it "extracts the RNT version from the sent_input_xml" do # rubocop:disable RSpec/ExampleLength
      rnt_check = described_class.new(
        sent_input_xml: <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <rnt version="0.4">
            <projet_travaux>
              <donnees_contextuelles>
                <version>0.1.0</version>
              </donnees_contextuelles>
            </projet_travaux>
          </rnt>
        XML
      )
      expect(rnt_check.schema_version).to eq("0.1.0")
    end
  end
end
