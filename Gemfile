# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.2.2"

# Core Rails
gem "rails", "~> 7.1"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"

# Redis
gem "redis", "~> 5.0"
gem "connection_pool", "~> 2.4"

# API
gem "rack-cors", "~> 2.0"
gem "jsonapi-serializer", "~> 2.2"

# Authentication
gem "bcrypt", "~> 3.1"
gem "jwt", "~> 2.8"

# Background jobs
gem "sidekiq", "~> 7.2"

# Pagination
gem "pagy", "~> 7.0"

# Swagger / OpenAPI docs
gem "rswag-api", "~> 2.13"
gem "rswag-ui", "~> 2.13"

# Validation
gem "dry-validation", "~> 1.10"
gem "dry-types", "~> 1.7"

# Observability
gem "lograge", "~> 0.14"

# Environment variables
gem "dotenv-rails", "~> 3.1"

group :development, :test do
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "rswag-specs", "~> 2.13"
  gem "shoulda-matchers", "~> 6.1"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "byebug"
end

group :development do
  gem "rubocop", "~> 1.60", require: false
  gem "rubocop-rails", "~> 2.23", require: false
  gem "rubocop-rspec", "~> 2.26", require: false
end

group :test do
  gem "simplecov", "~> 0.22", require: false
  gem "webmock", "~> 3.23"
  gem "timecop", "~> 0.9"
end
