# frozen_string_literal: true

RSpec.configure do |config|
  config.after do |example|
    next if ENV["CI"]

    exception = example.exception
    if exception
      location = example.metadata[:location]
      file = example.metadata[:file_path]

      puts "\n🔍 Test failed at: #{file}:#{location.split(':').last}" # rubocop:disable Lint/Output
      puts "💡 Re-run with: rspec #{file}:#{location.split(':').last}" # rubocop:disable Lint/Output

      debugger # rubocop:disable Lint/Debugger
    end
  end
end
