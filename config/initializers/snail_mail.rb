# Initializer to load SnailMail templates
Rails.application.config.after_initialize do
  Rails.logger.info "Loading SnailMail templates..."

  # Count registered templates
  template_count = SnailMail::Templates.available_templates.size
  Rails.logger.info "Loaded #{template_count} SnailMail templates"

  if template_count > 0
    # Log template info for debugging
    templates_by_size = {}

    [ :standard, :envelope ].each do |size|
      size_templates = SnailMail::Service.templates_for_size(size)
      templates_by_size[size] = size_templates
      Rails.logger.info "Templates for size #{size}: #{size_templates.inspect}"
    end

    # Log the default template
    default_template = SnailMail::Service.default_template
    Rails.logger.info "Default template: #{default_template}"
  else
    Rails.logger.warn "No templates were loaded!"
  end
end
