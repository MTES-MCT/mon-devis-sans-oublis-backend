# frozen_string_literal: true

require "fileutils"
require "open3"

# Class to handle ClamAV scanning
class ClamAv
  DATABASE_PATH = Rails.root.join("tmp/clamav-db")

  def self.database_exists?(database_path = DATABASE_PATH)
    return false unless Dir.exist?(database_path)

    db_files = Dir.glob("#{database_path}/**/*")
    db_files.any?
  end

  # Download the latest ClamAV database in a temporary directory
  def self.download_database!(database_path = DATABASE_PATH) # rubocop:disable Metrics/MethodLength
    return if database_exists?(database_path)

    tmp_conf_file = Tempfile.new("freshclam.conf", binmode: true)
    tmp_conf_file.write <<-CONFIG
      DatabaseDirectory #{database_path}
      DatabaseMirror database.clamav.net
    CONFIG
    tmp_conf_file.close

    begin
      FileUtils.mkdir_p(database_path)
      FileUtils.chmod(0o777, database_path)

      system("freshclam", "--config-file=#{tmp_conf_file.path}", "--datadir=#{database_path}")
    rescue StandardError
      FileUtils.rm_rf(database_path)
      raise
    end
  ensure
    File.delete(tmp_conf_file.path) if tmp_conf_file
  end

  # Scan a file using ClamAV
  def self.scan(filepath, autodownload_database: true, database_path: DATABASE_PATH) # rubocop:disable Metrics/MethodLength
    unless system("which clamscan > /dev/null 2>&1")
      raise NotImplemented, "ClamAV is not installed. Please install it to use this feature."
    end

    unless database_exists?(database_path)
      if autodownload_database
        download_database!(database_path)
        return scan(filepath, autodownload_database: false)
      end

      raise NotImplemented, "ClamAV is missing its database."
    end

    scan_with_clamav(filepath)
  end

  def self.scan_with_clamav(filepath) # rubocop:disable Metrics/MethodLength
    stdout, stderr, status = Open3.capture3(
      "clamscan", "--stdout", "--no-summary", "--database", DATABASE_PATH.to_s, filepath
    )

    case status.exitstatus
    when 2
      raise "ClamAV error: #{stderr.strip}"
    when 1
      false # Virus found
    when 0
      true # No virus found
    else
      raise "ClamAV error, no status: #{stdout.strip} #{stderr.strip}"
    end
  end
end
