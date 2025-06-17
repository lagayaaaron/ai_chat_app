module SidekiqAddOns
  def flushdb
    Sidekiq.redis(&:flushdb)
  end
end
Sidekiq.send(:extend, SidekiqAddOns) unless Sidekiq.respond_to?(:flushdb)

opts = {}
opts[:url] = if Rails.env.development?
  "redis://localhost:6379"
else
  Rails.application.credentials.dig(:kamal_secret, :redis_url)
end

if opts.key?(:url)
  Sidekiq.configure_server do |config|
    config.redis = opts
  end

  Sidekiq.configure_client do |config|
    config.redis = opts
  end

  ActiveJob::Base.queue_adapter = :sidekiq unless Rails.env.test?
end
