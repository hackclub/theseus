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
      link_to path, class: current_page?(path) ? 'active' : '', **options do
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
      link_to "show #{thing}?", url_for(thing => 'yeah')
    end
  end

  def render_checkbox(value)
    content_tag(:span, style: "color: var(--checkbox-#{value ? 'true' : 'false' })") { value ? "☑" : "☒" }
  end
end
