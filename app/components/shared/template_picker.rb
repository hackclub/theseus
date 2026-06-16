# frozen_string_literal: true

class Components::Shared::TemplatePicker < Components::Base
  Registry = SnailMail::Components::Registry

  def initialize(form:, name: :template, selected: nil, show_all: false)
    @form = form
    @name = name
    @selected = selected.to_s.presence
    @show_all = show_all
  end

  def view_template
    div(style: "margin-bottom:1rem") do
      select(
        name: "#{form.object_name}[#{name}]",
        id: "template-picker-select",
        style: "width: 100%;"
      ) do
        option(value: "", disabled: true, selected: selected.blank?) { "Choose template..." }
        templates.each do |tmpl|
          tname = tmpl[:name].to_s
          info = tmpl[:info]
          option(
            value: tname,
            selected: tname == selected
          ) { "#{tname.titleize} — #{info[:size].to_s.titleize}" }
        end
      end
    end
  end

  private

  attr_reader :form, :name, :selected, :show_all

  def templates
    names = show_all ? Registry.available_templates : Registry.available_single_templates
    names.map do |tname|
      info = Registry.template_info.find { |i| i[:name] == tname } || {}
      { name: tname, info: info }
    end.sort_by { |t| t[:info][:is_default] ? 0 : 1 }
  end
end
