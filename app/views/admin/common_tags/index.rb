# frozen_string_literal: true

class Views::Admin::CommonTags::Index < Views::Base
  def initialize(common_tags:)
    @common_tags = common_tags
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Common Tags",
      jumpcode_path: admin_common_tags_path,
      action_href: new_admin_common_tag_path,
      action_label: "+ New Tag"
    )

    if @common_tags.empty?
      div(class: "empty-state-lg text-muted") do
        p { "No common tags yet." }
        a(href: new_admin_common_tag_path) do
          button(class: "btn-success") { "+ New Tag" }
        end
      end
    else
      table do
        thead do
          tr do
            th { "Tag" }
            th { "YSWS" }
            th(class: "text-right") { "" }
          end
        end
        tbody do
          @common_tags.each do |common_tag|
            tr do
              td do
                span(class: "badge") { common_tag.tag }
              end
              td do
                if common_tag.implies_ysws
                  span(class: "badge badge-success") { "Yes" }
                else
                  span(class: "badge") { "No" }
                end
              end
              td(class: "actions-cell") do
                a(href: edit_admin_common_tag_path(common_tag), class: "icon-link") { "✎" }
                button_to "✕", admin_common_tag_path(common_tag), method: :delete, form: { class: "form-inline" }, class: "btn-link-danger", onclick: "return confirm('Delete this tag?')"
              end
            end
          end
        end
      end
    end
  end
end
