# frozen_string_literal: true

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via MDSO OCR olmOCR
    class MdsoOcrMarker < MdsoOcr
      DEFAULT_MODEL = "marker"

      def ocr
        "MdsoOcrMarker"
      end
    end
  end
end
