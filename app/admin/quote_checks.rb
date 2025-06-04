# frozen_string_literal: true

Rails.root.glob("app/admin/quote_checks/*.rb").each { |f| require f }
