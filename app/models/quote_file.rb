# frozen_string_literal: true

require "mime/types"

# Class to store uploaded Quote files, raw like
# TODO: clear if we keep storing file in double in the data binary field,
# AND also via active_storage-postgresq gem specific table via Postgres File OID
# See .find_or_create_file and #content methods
class QuoteFile < ApplicationRecord
  include ProcessingLogs
  include QuoteFileBackoffice
  include QuoteFileImagifiedPages
  include QuoteFileOcr

  has_one_attached :file
  has_many :quote_checks, dependent: :nullify, inverse_of: :file

  strip_attributes

  validates :filename, presence: true
  validates :content_type, presence: true
  validates :hexdigest, presence: true, uniqueness: { scope: :filename }

  validates :data, presence: true
  validates :file, attached: true, size: { less_than: 50.megabytes }

  # rubocop:disable Metrics/MethodLength
  def self.find_or_create_file(tempfile, filename, content_type: nil)
    hexdigest = hexdigest_for_file(tempfile)
    file = tempfile_to_file(tempfile, content_type:)

    existing_quote_file = find_by(filename:, hexdigest:)
    return existing_quote_file if existing_quote_file

    new_quote_file = new(
      filename: filename,
      content_type: file[:content_type],
      hexdigest: hexdigest,
      uploaded_at: Time.current
    )
    tempfile.rewind
    new_quote_file.data = tempfile.read
    raise QuoteReader::NoFileContentError if new_quote_file.data.blank?

    tempfile.rewind
    new_quote_file.file.attach(io: tempfile, filename: filename) # File.basename(tempfile.path)
    new_quote_file.save!

    new_quote_file
  end
  # rubocop:enable Metrics/MethodLength

  def self.hexdigest_for_file(tempfile)
    Digest::SHA256.file(tempfile).hexdigest
  end

  def self.tempfile_to_file(tempfile, content_type: nil) # rubocop:disable Metrics/MethodLength
    return unless tempfile

    content_type = [
      MIME::Types.type_for(tempfile.path).first&.content_type,
      content_type
    ].compact.first
    raise ArgumentError, "Missing content_type for tempfile #{tempfile.path}" unless content_type

    {
      io: tempfile,
      filename: File.basename(tempfile.path),
      content_type: content_type
    }
  end

  def extension
    File.extname(filename.to_s)&.delete_prefix(".") if filename
  end

  def local_path
    ActiveStorage::Blob.service.path_for(file.key) if file
  end

  def content
    data # OR file&.download
  end
end
