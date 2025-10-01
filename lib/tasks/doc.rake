# frozen_string_literal: true

namespace :doc do
  desc "Generate API documentation"
  task swagger: :environment do |_t, _args|
    Rake::Task["rswag:specs:swaggerize"].invoke(
      PATTERN: "spec/**/*_doc_spec.rb"
    )

    Rails.root.join("swagger/v1/quote_check_private_data_qa_attributes.json")
         .write(JSON.pretty_generate(MdsoApiSchema.quote_check_private_data_qa_attributes))
  end
end
