# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Logging
  config.log_level = :debug
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Cache
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    namespace: "user_service:cache",
    expires_in: 1.hour
  }

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
end
