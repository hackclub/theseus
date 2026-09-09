# frozen_string_literal: true

class SnailMailTemplateGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  desc "Generates a new snail mail template"

  class_option :description, type: :string, default: "A mail template", desc: "Template description"
  class_option :base_class, type: :string, default: "TemplateBase", desc: "Base class to inherit from (TemplateBase or HalfLetterComponent)"
  class_option :size, type: :string, default: "full", desc: "Template size (full or half_letter)"

  def create_template_file
    @class_name = file_name.camelize + "Template"
    @template_name = file_name.humanize.downcase
    @description = options[:description]
    @base_class = options[:base_class]
    @size = options[:size]

    template(
      "template.rb.erb",
      "app/lib/snail_mail/components/templates/#{file_name}_template.rb"
    )
  end

  private

  def file_name
    name.underscore
  end
end
