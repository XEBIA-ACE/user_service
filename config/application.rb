# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"

Bundler.require(*Rails.groups)

module UserService
  class Application < Rails::Application
    config.load_defaults 7.1

    # API-only mode
    config.api_only = true

    # Timezone
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    # Autoload paths
    config.autoload_paths += %W[
      #{config.root}/app/services
      #{config.root}/app/serializers
      #{config.root}/lib
    ]

    # Logging
    config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym
    config.log_tags = [:request_id]

    # Active Job queue adapter (Sidekiq)
    config.active_job.queue_adapter = :sidekiq

    # CORS is configured in initializers/cors.rb
    config.middleware.insert_before 0, Rack::Cors

    # Default locale
    config.i18n.default_locale = :en

    # Filter sensitive parameters from logs
    config.filter_parameters += %i[
      password password_confirmation token secret key authorization
    ]
  end
end
