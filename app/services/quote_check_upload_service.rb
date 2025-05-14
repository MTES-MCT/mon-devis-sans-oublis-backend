# frozen_string_literal: true

# This class is responsible for creating the quote by the upload.
class QuoteCheckUploadService
  attr_reader :tempfile, :filename,
              :profile, :renovation_type,
              :content_type, :metadata, :case_id, :parent_id,
              :file_text, :file_markdown,
              :reference, :source_name,
              :quote_check

  # rubocop:disable Metrics/ParameterLists
  def initialize( # rubocop:disable Metrics/MethodLength
    tempfile, filename, profile, renovation_type,
    content_type: nil, metadata: nil, case_id: nil, parent_id: nil,
    file_text: nil, file_markdown: nil,
    reference: nil, source_name: nil
  )
    @tempfile = tempfile
    @filename = filename

    @profile = profile
    @renovation_type = renovation_type

    @file_text = file_text
    @file_markdown = file_markdown

    @content_type = content_type
    @metadata = metadata
    @case_id = case_id
    @parent_id = parent_id
    @reference = reference
    @source_name = source_name
  end
  # rubocop:enable Metrics/ParameterLists

  def upload # rubocop:disable Metrics/MethodLength
    quote_file = QuoteFile.find_or_create_file(tempfile, filename, content_type:)

    @quote_check = QuoteCheck.create!(
      file: quote_file,

      profile:,
      renovation_type:,

      started_at: Time.current,

      metadata:,
      case_id:,
      parent_id:,
      reference:,
      source_name:,

      file_text:,
      file_markdown:
    )
  end
end
