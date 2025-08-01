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
    config.autoload_paths << Rails.root.join("lib")
    config.eager_load_paths << Rails.root.join("lib")

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
