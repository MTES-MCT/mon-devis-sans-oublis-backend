# frozen_string_literal: true

# Add imagified_pages to QuoteFile
module QuoteFileImagifiedPages
  extend ActiveSupport::Concern

  def imagified_pages=(images)
    # Encode each image in Base64 before saving
    super(images.map { |img| Base64.encode64(img) })
  end

  def imagified_pages
    # Decode back to binary when retrieving
    super&.map { |img| Base64.decode64(img) }
  end
end
