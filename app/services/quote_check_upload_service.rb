# frozen_string_literal: true

# This class is responsible for creating the quote by the upload.
class QuoteCheckUploadService
  attr_reader :tempfile, :filename, :profile,
              :content_type, :metadata, :parent_id,
              :file_text, :file_markdown,
              :quote_check

  # rubocop:disable Metrics/ParameterLists
  def initialize(
    tempfile, filename, profile,
    content_type: nil, metadata: nil, parent_id: nil,
    file_text: nil, file_markdown: nil
  )
    @tempfile = tempfile
    @filename = filename
    @profile = profile

    @content_type = content_type
    @metadata = metadata
    @parent_id = parent_id

    @file_text = file_text
    @file_markdown = file_markdown
  end
  # rubocop:enable Metrics/ParameterLists

  def upload
    quote_file = QuoteFile.find_or_create_file(tempfile, filename, content_type:)

    @quote_check = QuoteCheck.create!(
      file: quote_file,
      profile:,
      started_at: Time.current,

      metadata:,
      parent_id:,

      file_text:,
      file_markdown:
    )
  end
end
