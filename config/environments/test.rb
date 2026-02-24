# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=3600" }

  config.consider_all_requests_local = true
  config.cache_store = :null_store

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test

  # Raise exceptions on deprecation notices
  config.active_support.deprecation = :raise
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = false
end
