# frozen_string_literal: true

# Add imagified_pages to QuoteFile
module QuoteFileOcr
  extend ActiveSupport::Concern

  included do
    scope :ocrable, -> { where("content_type LIKE ?", "image/%").or(where("content_type LIKE ?", "%pdf%")) }
    scope :non_ocred, -> { where(ocr_result: nil) }
    scope :ocred, -> { where.not(ocr_result: nil) }
  end

  def ocr
    return unless ocrable? || !force_ocr

    read_attribute(:ocr) || QuoteReader::Global::DEFAULT_OCR # TODO: save in a field
  end

  def ocr_used
    (ocred? && ocr) || "PDF natif"
  end

  def ocrable?
    content_type&.include?("pdf") ||
      only_ocrable?
  end

  def ocred?
    ocr_result.present?
  end

  def only_ocrable?
    content_type&.start_with?("image/") ||
      false
  end
end
