# frozen_string_literal: true

# Thin wrapper around Redis for application-level caching.
# Keys are namespaced automatically so callers use simple identifiers.
#
# Usage:
#   CacheService.fetch("user:#{id}", ttl: 5.minutes) { User.find(id) }
module CacheService
  NAMESPACE = "user_service"

  module_function

  # Returns cached value or executes the block, stores, and returns the result.
  def fetch(key, ttl: 1.hour, &block)
    namespaced = "#{NAMESPACE}:#{key}"

    cached = RedisClient.with { |conn| conn.get(namespaced) }
    return JSON.parse(cached, symbolize_names: true) if cached

    value = block.call
    RedisClient.with { |conn| conn.setex(namespaced, ttl.to_i, value.to_json) }
    value
  end

  # Reads a value without populating. Returns nil if missing.
  def read(key)
    namespaced = "#{NAMESPACE}:#{key}"
    cached = RedisClient.with { |conn| conn.get(namespaced) }
    cached ? JSON.parse(cached, symbolize_names: true) : nil
  end

  # Writes a value with optional TTL.
  def write(key, value, ttl: 1.hour)
    namespaced = "#{NAMESPACE}:#{key}"
    RedisClient.with { |conn| conn.setex(namespaced, ttl.to_i, value.to_json) }
  end

  # Removes a key from the cache.
  def delete(key)
    namespaced = "#{NAMESPACE}:#{key}"
    RedisClient.with { |conn| conn.del(namespaced) }
  end

  # Removes multiple keys matching a pattern (use sparingly — SCAN based).
  def delete_pattern(pattern)
    namespaced = "#{NAMESPACE}:#{pattern}"
    RedisClient.with do |conn|
      cursor = "0"
      loop do
        cursor, keys = conn.scan(cursor, match: namespaced, count: 100)
        conn.del(*keys) if keys.any?
        break if cursor == "0"
      end
    end
  end
end
