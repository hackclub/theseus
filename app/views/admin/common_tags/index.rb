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
      div(style: "text-align:center;padding:3rem 1rem;color:var(--foreground2);") do
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
            th(style: "text-align: right;") { "" }
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
              td(style: "text-align:right;white-space:nowrap;") do
                a(href: edit_admin_common_tag_path(common_tag), style: "color:var(--foreground2);margin-right:0.5rem;") { "✎" }
                button_to "✕", admin_common_tag_path(common_tag), method: :delete, form: { style: "display:inline;" }, style: "background:none;border:none;color:var(--red);cursor:pointer;font:inherit;padding:0;", onclick: "return confirm('Delete this tag?')"
              end
            end
          end
        end
      end
    end
  end
end
