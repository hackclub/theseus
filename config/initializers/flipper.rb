Rails.application.configure do
  config.flipper.memoize = true
  config.flipper.preload = true
end

Flipper::UI.configure do |config|
  if Rails.env.production?
    config.banner_text = "this is production. be careful."
    config.banner_class = "warning"
  end

  config.actor_names_source = ->(actor_ids) do
    actor_names = {}

    actor_ids.each do |actor_id|
      prefix, hash = actor_id.split("!", 2)
      next unless hash.present?

      prefix_info = Shortcodes.public_id_prefixes[prefix]
      next unless prefix_info

      model = prefix_info[:model].constantize rescue next
      record = model.find_by_hashid(hash)
      next unless record

      name = record.try(:username) || record.try(:email) || record.try(:name) || record.public_id
      actor_names[record.public_id] = name
    end

    actor_names.compact_blank
  end

  config.descriptions_source = ->(_keys) { Rails.configuration.flipper_features }
end
