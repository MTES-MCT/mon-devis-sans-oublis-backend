# frozen_string_literal: true

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via MDSO OCR olmOCR
    class MdsoOcrDotsOcr < MdsoOcr
      DEFAULT_MODEL = "dotsocr"

      def ocr
        "MdsoOcrDotsOcr"
      end
    end
  end
end
