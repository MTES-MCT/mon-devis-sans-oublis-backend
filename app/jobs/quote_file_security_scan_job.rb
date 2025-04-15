# frozen_string_literal: true

# Job to perform security scan on QuoteFile
class QuoteFileSecurityScanJob < ApplicationJob
  queue_as :default

  def perform(quote_file_id) # rubocop:disable Metrics/MethodLength
    quote_file = QuoteFile.find(quote_file_id)
    return unless quote_file

    begin
      # Write tmp file
      tmp_file = Tempfile.new("quote_file_#{quote_file.id}", binmode: true)
      tmp_file.write(quote_file.content)
      tmp_file.rewind
      tmp_file.close

      # Scan the file
      security_scan_good = ClamAv.scan(tmp_file.path)
    ensure
      File.delete(tmp_file.path) if tmp_file
    end

    quote_file.update!(security_scan_good:)
  end
end
