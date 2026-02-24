# syntax=docker/dockerfile:1

# =============================================================================
# Stage 1: base — shared Ruby runtime
# =============================================================================
ARG RUBY_VERSION=3.2.2
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /app

# Install runtime OS dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq5 \
      curl \
    && rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH="/usr/local/bundle"

# =============================================================================
# Stage 2: build — install gems and precompile assets
# =============================================================================
FROM base AS build

# Install build-time dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files first to leverage Docker layer cache
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}/ruby/*/cache" \
           "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git"

# Copy application source
COPY . .

# Precompile bootsnap code for faster boot
RUN bundle exec bootsnap precompile app/ lib/

# =============================================================================
# Stage 3: final — minimal production image
# =============================================================================
FROM base AS final

# Create non-root user for running the application
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Copy installed gems from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"

# Copy pre-compiled application
COPY --from=build --chown=rails:rails /app /app

# Create writable directories
RUN mkdir -p /app/tmp/pids /app/log && \
    chown -R rails:rails /app/tmp /app/log

USER rails

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
