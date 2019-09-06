# frozen_string_literal: true

Resque.redis = Redis.new(
  url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' },
  password: ENV.fetch('REDIS_PASSWORD') { '' }
)

