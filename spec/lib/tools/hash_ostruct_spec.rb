# frozen_string_literal: true

require "rails_helper"

RSpec.describe HashOstruct, type: :service do
  describe "#to_ostruct_recursive" do
    # rubocop:disable RSpec/MultipleExpectations
    # rubocop:disable Style/OpenStructUse
    it "converts a nested hash to OpenStruct recursively" do # rubocop:disable RSpec/ExampleLength
      hash = described_class.new({
                                   "name" => "Alice",
                                   "details" => {
                                     "age" => 30,
                                     "address" => [{
                                       "city" => "Wonderland",
                                       "zip" => "12345"
                                     }]
                                   }
                                 })

      ostruct = hash.to_ostruct_recursive

      expect(ostruct).to be_a(OpenStruct)
      expect(ostruct.name).to eq("Alice")
      expect(ostruct.details).to be_a(OpenStruct)
      expect(ostruct.details.age).to eq(30)
      expect(ostruct.details.address.first).to be_a(OpenStruct)
      expect(ostruct.details.address.first.city).to eq("Wonderland")
      expect(ostruct.details.address.first.zip).to eq("12345")
    end
    # rubocop:enable Style/OpenStructUse
    # rubocop:enable RSpec/MultipleExpectations
  end
end
