# frozen_string_literal: true

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via MDSO OCR olmOCR
    class MdsoOcrOlmOcr < MdsoOcr
      DEFAULT_MODEL = "olmocr"

      def ocr
        "MdsoOcrOlmOcr"
      end
    end
  end
end
