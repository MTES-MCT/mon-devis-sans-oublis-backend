# frozen_string_literal: true

namespace :quote_files do
  desc "Imagify pages on PDF QuoteFiles"
  task imagify_pages: :environment do |_t, _args|
    QuoteFile.where(
      content_type: "application/pdf",
      imagified_pages: nil
    ).find_each do |quote_file|
      QuoteFileImagifyPdfJob.new.perform(quote_file.id)
    end
  end
end
