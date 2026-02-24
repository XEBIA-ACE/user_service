# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true

  config.consider_all_requests_local = false

  # Logging — use lograge for structured JSON logs in production
  config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym
  config.log_formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Cache with Redis
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL"),
    namespace: "user_service:cache",
    expires_in: 1.hour,
    pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
    pool_timeout: 5
  }

  # Force SSL in production
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"

  config.active_record.verbose_query_logs = false
  config.active_support.report_deprecations = false
end
