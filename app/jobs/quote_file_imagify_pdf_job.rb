# frozen_string_literal: true

# Job to extract images of pages of an existing PDF QuoteFile
class QuoteFileImagifyPdfJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :low

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "#{self.class.name}-#{queue_name}-#{arguments.first}" }
  )

  def perform(quote_file_id)
    quote_file = QuoteFile.find_by(id: quote_file_id)
    return unless quote_file&.content_type == "application/pdf"

    imagified_pages = QuoteReader::Pdf.new(quote_file.file.download).to_images
    quote_file.update!(imagified_pages: imagified_pages)
  end
end
