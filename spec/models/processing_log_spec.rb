# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessingLog do
  subject(:processing_log) { described_class.new }

  describe "validations" do
    before { processing_log.validate }

    it "validates presence of input" do
      expect(processing_log).not_to be_valid
    end

    it "adds error if input is blank and no processable" do
      expect(
        processing_log.errors[:input_parameters]
      ).to include("doit être présent si pas de processable associé")
    end
  end
end
