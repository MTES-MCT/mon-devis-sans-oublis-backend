# frozen_string_literal: true

Rails.application.configure do
  config.good_job = {
    queues: "*", # critical,default;low
    enable_cron: true,
    cron: {
      quote_checks_timeout_job: {
        cron: "*/5 * * * *",
        class: "QuoteChecksTimeoutJob"
      }
    },
    dashboard_default_locale: config.i18n.default_locale
  }
end

if Rails.env.production?
  GoodJob::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(ENV.fetch("GOOD_JOB_USERNAME"), username) &
      ActiveSupport::SecurityUtils.secure_compare(ENV.fetch("GOOD_JOB_PASSWORD"), password)
  end
end

module GoodJob
  # Re-implement https://github.com/bensheldon/good_job/blob/main/app/models/good_job/i18n_config.rb
  # to ensure GoodJob is limited to the same locales as the application
  class I18nConfig < ::I18n::Config
    BACKEND = I18n::Backend::Simple.new
    AVAILABLE_LOCALES = Rails.application.config.i18n.available_locales
    AVAILABLE_LOCALES_SET = AVAILABLE_LOCALES.inject(Set.new) { |set, locale| set << locale.to_s << locale.to_sym }

    def backend
      BACKEND
    end

    def available_locales
      AVAILABLE_LOCALES
    end

    def available_locales_set
      AVAILABLE_LOCALES_SET
    end

    def default_locale
      GoodJob.configuration.dashboard_default_locale || I18n.default_locale
    end
  end
end
