# frozen_string_literal: true

# Add imagified_pages to QuoteFile
module QuoteFileOcr
  extend ActiveSupport::Concern

  def ocr
    return unless ocrable? || !force_ocr

    read_attribute(:ocr) || QuoteReader::Global::DEFAULT_OCR # TODO: save in a field
  end

  def ocrable?
    content_type&.start_with?("image/") ||
      false
  end
end
