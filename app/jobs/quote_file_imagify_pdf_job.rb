# frozen_string_literal: true

# Job to extract images of pages of an existing PDF QuoteFile
class QuoteFileImagifyPdfJob < ApplicationJob
  queue_as :default

  def perform(quote_file_id)
    quote_file = QuoteFile.find(quote_file_id)
    return unless quote_file&.content_type == "application/pdf"

    imagified_pages = QuoteReader::Pdf.new(quote_file.file.download).to_images
    quote_file.update!(imagified_pages: imagified_pages)
  end
end
