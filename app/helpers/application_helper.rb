module ApplicationHelper
  include ButtonHelper

  def admin_tool(class_name: "", element: "div", **options, &block)
    return unless current_user&.is_admin?
    concat content_tag(element, class: "admin-tool #{class_name}", **options, &block)
  end

  def dev_tool(class_name: "", element: "div", **options, &block)
    return unless Rails.env.development?
    concat content_tag(element, class: "dev-tool #{class_name}", **options, &block)
  end

  def nav_item(path, text, options = {})
    content_tag("li") do
      link_to path, class: current_page?(path) ? "active" : "", **options do
        text
      end
    end
  end

  def zenv_link(model)
    return unless model.zenventory_url.present?
    admin_tool element: :span do
      link_to "Edit on Zenventory", model.zenventory_url, target: "_blank"
    end
  end

  def inspector_toggle(thing)
    admin_tool(class_name: "mt4") do
      param = "inspect_#{thing}".to_sym
      if params[param]
        link_to "uninspect #{thing}?", url_for(param => nil)
      else
        link_to "inspect #{thing}?", url_for(param => "yeah")
      end
    end
  end

  def param_toggle(thing)
    if params[thing]
      link_to "hide #{thing}?", url_for(thing => nil)
    else
      link_to "show #{thing}?", url_for(thing => "yeah")
    end
  end

  def render_checkbox(value)
    content_tag(:span, style: "color: var(--checkbox-#{value ? "true" : "false"})") { value ? "☑" : "☒" }
  end

  def copy_to_clipboard(clipboard_value, tooltip_direction: "n", **options, &block)
    # If block is not given, use clipboard_value as the rendered content
    block ||= ->(_) { clipboard_value }
    return yield if options.delete(:if) == false

    css_classes = "pointer tooltipped tooltipped--#{tooltip_direction} #{options.delete(:class)}"
    tag.span "data-copy-to-clipboard": clipboard_value, class: css_classes, "aria-label": options.delete(:label) || "click to copy...", **options, &block
  end

  def render_json_example(obj)
    transformed = recursively_transform_values(obj) do |v|
      "<kbd>#{v}</kbd>"
    end
    copy_to_clipboard(JSON.pretty_generate(obj)) do
      content_tag("div") do
        content_tag("pre") do
          "<br/>".html_safe + JSON.pretty_generate(transformed).html_safe
        end +
        content_tag("small") do
          "(you can click that hunk of JSON to copy it if you like)"
        end
      end
    end
  end

  def available_tags(selected_tags = [])
    Rails.cache.fetch("available_tags", expires_in: 1.day) do
      common_tags = CommonTag.pluck(:tag)
      warehouse_order_tags = Warehouse::Order.all_tags
      letter_tags = Letter.all_tags

      (common_tags + (warehouse_order_tags + letter_tags).compact_blank.sort).uniq
    end
  end

  private

  def recursively_transform_values(obj, &block)
    case obj
    when Hash
      obj.transform_values { |v| recursively_transform_values(v, &block) }
    when Array
      obj.map { |v| recursively_transform_values(v, &block) }
    when String, Numeric, TrueClass, FalseClass, NilClass
      block.call(obj)
    else
      obj
    end
  end
end
