# frozen_string_literal: true

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i

threads min_threads_count, max_threads_count

port        ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

pidfile     ENV["PIDFILE"] if ENV["PIDFILE"]

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

workers ENV.fetch("WEB_CONCURRENCY", 2).to_i if ENV["RAILS_ENV"] == "production"
preload_app! if ENV["RAILS_ENV"] == "production"
