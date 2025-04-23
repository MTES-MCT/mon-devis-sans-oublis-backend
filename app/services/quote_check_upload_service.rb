# frozen_string_literal: true

# This class is responsible for creating the quote by the upload.
class QuoteCheckUploadService
  attr_reader :tempfile, :filename, :profile,
              :content_type, :metadata, :parent_id,
              :file_text, :file_markdown,
              :source_name,
              :quote_check

  # rubocop:disable Metrics/ParameterLists
  def initialize(
    tempfile, filename, profile,
    content_type: nil, metadata: nil, parent_id: nil,
    file_text: nil, file_markdown: nil,
    source_name: nil
  )
    @tempfile = tempfile
    @filename = filename
    @profile = profile
    @file_text = file_text
    @file_markdown = file_markdown

    @content_type = content_type
    @metadata = metadata
    @parent_id = parent_id
    @source_name = source_name
  end
  # rubocop:enable Metrics/ParameterLists

  def upload # rubocop:disable Metrics/MethodLength
    quote_file = QuoteFile.find_or_create_file(tempfile, filename, content_type:)

    @quote_check = QuoteCheck.create!(
      file: quote_file,
      profile:,
      started_at: Time.current,

      metadata:,
      parent_id:,
      source_name:,

      file_text:,
      file_markdown:
    )
  end
end
