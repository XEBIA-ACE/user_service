# frozen_string_literal: true

# Redis connection pool configuration.
# Uses connection_pool gem to manage a pool of Redis connections,
# preventing thread contention under load.

redis_config = Rails.application.config_for(:redis)

REDIS_POOL = ConnectionPool.new(
  size: ENV.fetch("REDIS_POOL_SIZE", 5).to_i,
  timeout: ENV.fetch("REDIS_POOL_TIMEOUT", 3).to_i
) do
  Redis.new(
    url: redis_config[:url],
    timeout: redis_config[:timeout] || 1,
    reconnect_attempts: redis_config[:reconnect_attempts] || 3,
    logger: Rails.logger
  )
end

# Convenience wrapper — yields a Redis connection from the pool.
# Usage: RedisClient.with { |conn| conn.get("key") }
module RedisClient
  def self.with(&block)
    REDIS_POOL.with(&block)
  end
end

Rails.logger.info "[Redis] Connection pool initialized (size=#{REDIS_POOL.size})"
