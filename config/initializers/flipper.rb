Rails.application.configure do
  config.flipper.memoize = true
  config.flipper.preload = true
end

Flipper::UI.configure do |config|
  if Rails.env.production?
    config.banner_text = "this is production. be careful."
    config.banner_class = "warning"
  end

  config.descriptions_source = ->(_keys) { Rails.configuration.flipper_features }
end
