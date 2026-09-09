Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.enabled_environments = %w[production staging]
  config.send_default_pii = false

  config.traces_sample_rate = 0.1

  config.before_send = lambda do |event, _hint|
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    event.request&.data = filter.filter(event.request.data) if event.request&.data.is_a?(Hash)
    event.extra = filter.filter(event.extra) if event.extra.is_a?(Hash)
    event
  end
end
