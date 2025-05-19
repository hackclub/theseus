# Initializer to load SnailMail templates
Rails.application.config.after_initialize do
  SnailMail::Templates.available_templates
end
