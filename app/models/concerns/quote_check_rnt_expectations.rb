# frozen_string_literal: true

require "nokogiri"

# Add expectations
module QuoteCheckRntExpectations
  extend ActiveSupport::Concern

  included do
    validate :expected_rnt_input_xml_as_array, if: -> { expected_rnt_input_xml? }

    scope :with_expected_rnt_value, -> { where.not(expected_rnt_input_xml: nil) }
  end

  def expected_rnt_input_xml?
    expected_rnt_input_xml.present?
  end

  def expected_rnt_input_xml_as_array # rubocop:disable Metrics/MethodLength
    return unless expected_rnt_input_xml

    if expected_rnt_input_xml.is_a?(String)
      begin
        doc = Nokogiri::XML(expected_rnt_input_xml, &:strict)
        self.expected_rnt_input_xml = doc.to_xml(indent: 2)
      rescue Nokogiri::XML::SyntaxError => e
        errors.add(:expected_rnt_input_xml,
                   "must be a valid XML document: #{e.message}")
      end
    else
      errors.add(:expected_rnt_input_xml,
                 "must be a string")
    end
  end
end
