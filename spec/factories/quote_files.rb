# frozen_string_literal: true

require "marcel"

FactoryBot.define do
  factory :quote_file do
    uploaded_at { Time.zone.now }

    transient do
      file { nil }
      filepath { file ? Pathname.new(file.path) : Rails.root.join("spec/fixtures/files/quote_files/Devis_test.pdf") }
    end

    filename { filepath&.basename&.to_s }
    sequence(:hexdigest) { filepath ? "#{QuoteFile.hexdigest_for_file(filepath)} #{it}" : nil }
    content_type do
      if filepath
        MIME::Types.type_for(filepath.to_s).first&.content_type || # From file name
          Marcel::MimeType.for(Pathname.new(filepath).to_s) # From file content
      end
    end

    after(:build) do |quote_file, evaluator|
      if evaluator.filepath
        data = evaluator.filepath.open.read

        quote_file.data = data
        quote_file.file.attach(
          io: StringIO.new(data),
          filename: quote_file.filename,
          content_type: quote_file.content_type
        )
      end
    end
  end
end
