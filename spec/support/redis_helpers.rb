# frozen_string_literal: true

# Flushes the test Redis database before each spec that uses it.
RSpec.configure do |config|
  config.before(:each, :redis) do
    RedisClient.with(&:flushdb)
  end
end
