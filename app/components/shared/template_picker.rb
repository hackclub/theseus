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
    render Primer::Alpha::SelectPanel.new(
      title: "Select template",
      size: :large,
      fetch_strategy: :local,
      dynamic_label: true,
      select_variant: :single,
      form_arguments: { builder: form, name: name },
      id: "template-picker-panel"
    ) do |panel|
      panel.with_show_button(scheme: :secondary, block: true) do |btn|
        btn.with_leading_visual_icon(icon: :paintbrush)
        if selected.present?
          plain selected.to_s.titleize
        else
          span(class: "kv-label") { "Choose template..." }
        end
      end

      templates.each do |tmpl|
        info = tmpl[:info]
        panel.with_item(
          label: tmpl[:name].to_s.titleize,
          content_arguments: { data: { value: tmpl[:name].to_s } },
          data: { filter_string: "#{tmpl[:name]} #{info[:size]}" },
          active: tmpl[:name].to_s == selected
        ) do |item|
          item.with_description { "#{info[:size].to_s.titleize}" }
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
