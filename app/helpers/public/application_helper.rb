module Public::ApplicationHelper
  def w95_title_button_to(label, url)
    content_tag("button", nil, {"aria-label"=>label, "onclick"=>%(window.location.href='#{url}';)})
  end

  def back_office_tool(class_name: "", element: "div", **options, &block)
    return unless current_user
    concat content_tag(element, class: "back-office-tool #{class_name}", **options, &block)
  end
end