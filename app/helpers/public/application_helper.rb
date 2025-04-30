module Public::ApplicationHelper
  def w95_title_button_to(label, url)
    content_tag("button", nil, {"aria-label"=>label, "onclick"=>%(window.location.href='#{url}';)})
  end
end