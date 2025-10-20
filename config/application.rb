# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# include the DSFR View Components
require "dsfr/assets"
require "dsfr/components"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MesDevisSansOublis
  # Application configuration
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Generated via `rails db:encryption:init`
    config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", nil)
    config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", nil)
    config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", nil)

    config.i18n.default_locale = :fr
    config.i18n.fallbacks = [:fr]
    config.i18n.available_locales = [:fr]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Rails.autoloaders.main.push_dir(Rails.root.join("lib"), namespace: nil)
    loader = Rails.autoloaders.main
    # 1) Load lib/ as a whole as usual
    loader.push_dir Rails.root.join("lib")
    # 2) Make these subfolders FLAT (no namespace from folder names)
    loader.collapse Rails.root.join("lib/tools")
    loader.collapse Rails.root.join("lib/data_sources")
    loader.collapse Rails.root.join("lib/rnt")

    # Don't generate system test files.
    config.generators.system_tests = nil
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.autoload_lib(ignore: %w[assets tasks])

    config.active_job.queue_adapter = :good_job

    config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST", nil) }

    require_relative "custom"
  end
end
