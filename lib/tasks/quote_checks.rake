# frozen_string_literal: true

require "parallel"
require "concurrent"

def print_table(headers, rows) # rubocop:disable Metrics/AbcSize
  widths = headers.map.with_index { |h, i| [h.length, *rows.map { |r| r[i].to_s.length }].max }

  puts headers.zip(widths).map { |h, w| h.ljust(w) }.join(" | ")
  puts "-" * (widths.sum + (3 * (headers.size - 1)))

  rows.each do |row|
    puts row.zip(widths).map { |c, w| c.to_s.ljust(w) }.join(" | ")
  end
end

namespace :quote_checks do # rubocop:disable Metrics/BlockLength
  desc "Caracters count of QuoteChecks"
  task caracters_count: :environment do |_t, _args|
    range_size = 500

    total_caracters = QuoteCheck.group("LENGTH(text) / #{range_size}").count
    puts "Caracters Count Range,Count"
    sum = 0
    total_caracters
      .sort_by { |range, _count| range.nil? ? -1 : range * range_size } # Sort by range
      .each do |range, count|
        sum += count
        puts "#{range.nil? ? -1 : range * range_size},#{sum}"
      end
    nil
  end

  desc "Create a QuoteCheck against local file(s) or by diretory"
  task :create, [:file_path] => :environment do |_t, args|
    file_path = args[:file_path]

    if File.directory?(file_path)
      Dir.foreach(file_path) do |entry|
        sub_file_path = File.join(file_path, entry)
        next unless File.file?(sub_file_path) && entry != ".DS_Store"

        Rake::Task["quote_checks:create"].reenable
        Rake::Task["quote_checks:create"].invoke(sub_file_path)
      end
    else
      puts "Error: File does not exist. Please check the path and try again." unless File.exist?(file_path)

      file = File.open(file_path)
      filename = File.basename(file_path)

      quote_check = QuoteCheckService.new(
        file, filename,
        "artisan",
        "geste",
        source_name: "mdso_bo"
      ).check

      puts JSON.pretty_generate(quote_check.attributes)
      puts "QuoteCheck created with id: #{quote_check.id}"
    end
  end

  desc "Run Fiability checks on flagged QuoteChecks in database with expecting results"
  task fiability: :environment do |_t, _args| # rubocop:disable Metrics/BlockLength
    # Anonymous temporary classes linked to test source database
    class QuoteFileToTest < QuoteFile # rubocop:disable Lint/ConstantDefinitionInBlock
      establish_connection :test_source

      def readonly?
        true
      end
    end

    # Anonymous temporary classes linked to test source database
    class QuoteCheckToTest < QuoteCheck # rubocop:disable Lint/ConstantDefinitionInBlock
      establish_connection :test_source

      belongs_to :file, class_name: "QuoteFileToTest"

      default_scope { with_expected_value }

      def readonly?
        true
      end
    end

    total_items = Concurrent::AtomicFixnum.new(0)
    total_differences = Concurrent::AtomicFixnum.new(0)

    QuoteCheckToTest.includes(:file).order(created_at: :desc).find_in_batches do |source_quote_checks| # rubocop:disable Metrics/BlockLength
      Parallel.each(source_quote_checks, in_threads: Parallel.processor_count) do |source_quote_check| # rubocop:disable Metrics/BlockLength
        source_quote_file = source_quote_check.file

        tempfile = Tempfile.new(
          source_quote_file.filename,
          content_type: source_quote_file.content_type
        )
        tempfile.binmode # Ensure it handles binary data properly
        tempfile.write(source_quote_file.content)
        tempfile.rewind

        quote_check_service = QuoteCheckService.new(
          tempfile, source_quote_file.filename,
          source_quote_check.profile,
          source_quote_check.renovation_type,
          content_type: source_quote_file.content_type,
          file_text: source_quote_check.file_text,
          file_markdown: source_quote_check.file_markdown,
          metadata: source_quote_check.metadata,
          case_id: nil, # can not reuse it,
          parent_id: nil, # can not reuse it,
          reference: nil, # can not reuse it,
          source_name: "mdso_bo"
        )
        new_quote_check = quote_check_service.quote_check
        new_quote_check = QuoteCheckCheckJob.new.perform(new_quote_check.id)

        max_errors_count = [
          new_quote_check.validation_errors.size,
          source_quote_check.expected_validation_errors.size
        ].max
        current_items = source_quote_check.expected_validation_errors.size
        total_items.increment(current_items)

        current_differences = Fiability.count_differences(
          new_quote_check.validation_errors,
          source_quote_check.expected_validation_errors
        )
        total_differences.increment(current_differences)

        puts "QuoteCheck #{source_quote_check.id}"
        print_table(%w[index Expected Result Match?], (0...max_errors_count).to_a.map do |index|
          [
            index,
            source_quote_check.expected_validation_errors[index],
            new_quote_check.validation_errors[index],
            new_quote_check.validation_errors[index] == source_quote_check.expected_validation_errors[index] ? "✅" : "❌"
          ]
        end)
        puts "Number of Difference(s): #{current_differences} / #{current_items} items = #{(1 - (current_differences.to_f / current_items)).round(2)}" # rubocop:disable Layout/LineLength

        puts ""
      end

      puts "ALBERT_MODEL wished: #{ENV.fetch('ALBERT_MODEL', nil)}"
      puts "ALBERT_MODEL used: #{Llms::Albert.new('').model}"
      puts "MISTRAL_MODE wished: #{ENV.fetch('MISTRAL_MODEL', nil)}"
      puts "MISTRAL_MODEL used: #{Llms::Mistral.new('').model}"

      puts "Number of Difference(s): #{total_differences.value}"
      fiability = 1 - (total_differences.value.to_f / total_items.value)
      puts "Fiability of #{fiability.round(2)} / 1 (best)"

      succeed = fiability >= Float(ENV.fetch("FIABILITY_THRESHOLD"))
      puts succeed ? "✅ Succeed" : "❌ FAILED"

      exit 1 unless succeed
    end
  end

  desc "Recheck a QuoteCheck"
  task :recheck, [:quote_check_id] => :environment do |_t, args|
    raise ArgumentError, "You must provide quote_check_id" unless args[:quote_check_id]

    QuoteCheckCheckJob.perform_later(args[:quote_check_id])
    puts "QuoteCheckCheckJob enqueued for ID: #{args[:quote_check_id]}"
  end

  desc "QuoteCheck with incoherent validation errors / controls counts"
  task incoherent_validation_countss: :environment do |_t, _args|
    # it.validation_errors&.count
    # validation_controls_count
    QuoteCheck
  end
end
