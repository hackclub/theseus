# Initializer to load SnailMail templates
Rails.application.config.to_prepare do
  # Eager load templates for descendants lookup
  templates_dir = Rails.root.join("app", "lib", "snail_mail", "components", "templates")
  Rails.autoloaders.main.eager_load_dir(templates_dir)

  # Verify templates are loaded
  SnailMail::Components::Registry.available_templates
end
