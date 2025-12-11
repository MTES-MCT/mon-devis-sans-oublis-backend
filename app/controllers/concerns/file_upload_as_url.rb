# frozen_string_literal: true

require "faraday"

# Concern to handle file uploads via URL paths
module FileUploadAsUrl
  extend ActiveSupport::Concern

  class FileUploadAsUrlError < StandardError; end
  class DownloadFileError < FileUploadAsUrlError; end
  class InvalidFileUrlError < FileUploadAsUrlError; end
  class UnauthorizedFileUrlError < FileUploadAsUrlError; end

  protected

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def file_upload_as_url(file_param) # rubocop:disable Metrics/MethodLength
    return file_param if !file_param.is_a?(String) ||
                         file_param.respond_to?(:tempfile)

    uri = begin
      URI.parse(file_param)
    rescue URI::InvalidURIError => e
      raise InvalidFileUrlError, e
    end
    raise InvalidFileUrlError, "Only HTTPS URLs are allowed" unless uri.is_a?(URI::HTTPS)

    uri_s = uri.to_s

    unless ENV.fetch("MDSO_ALLOWED_FILE_UPLOAD_URL_HOSTS", "").split(",").any? do |host|
      host.present? && uri_s.start_with?(host.strip)
    end
      exception = UnauthorizedFileUrlError.new("URI #{uri_s} is not allowed")
      ErrorNotifier.notify(exception)
      raise exception
    end

    response = Faraday.get(uri_s)
    unless response.success?
      exception = DownloadFileError.new("Failed to fetch file from URL #{uri_s} : #{response.status}")
      ErrorNotifier.notify(exception)
      raise exception
    end

    content_type = response.headers["content-type"]
    preferred_extension = File.extname(uri.path).presence ||
                          (content_type.present? && MIME::Types[content_type].first&.preferred_extension)
    temp_file = Tempfile.new(["upload", ".#{preferred_extension}"])
    temp_file.binmode
    temp_file.write(response.body)
    temp_file.rewind

    ActionDispatch::Http::UploadedFile.new(
      filename: File.basename(uri.path),
      type: response.headers["content-type"],
      tempfile: temp_file
    )
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
end
