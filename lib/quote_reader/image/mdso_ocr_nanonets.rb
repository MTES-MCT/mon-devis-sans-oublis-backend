# frozen_string_literal: true

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via MDSO OCR olmOCR
    class MdsoOcrNanonets < MdsoOcr
      DEFAULT_MODEL = "nanonets"

      def ocr
        "MdsoOcrNanonets"
      end
    end
  end
end
