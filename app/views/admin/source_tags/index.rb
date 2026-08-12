# frozen_string_literal: true

class Views::Admin::SourceTags::Index < Views::Base
  def initialize(source_tags:)
    @source_tags = source_tags
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Source Tags",
      jumpcode_path: admin_source_tags_path,
      action_href: new_admin_source_tag_path,
      action_label: "+ New Source Tag"
    )

    if @source_tags.any?
      table do
        thead do
          tr do
            th { "Slug" }
            th { "Name" }
            th { "Owner" }
            th { "Orders" }
            th(style: "text-align: right;") { "" }
          end
        end
        tbody do
          @source_tags.each do |source_tag|
            tr do
              td do
                a(href: admin_source_tag_path(source_tag), style: "text-decoration:none;") do
                  span(class: "badge badge-info") { source_tag.slug }
                end
              end
              td(style: "font-weight:600;") { source_tag.name }
              td(class: "text-muted") { source_tag.owner.presence || "—" }
              td(class: "text-muted") { source_tag.warehouse_orders.size.to_s }
              td(style: "text-align:right;white-space:nowrap;") do
                a(href: edit_admin_source_tag_path(source_tag), style: "color:GrayText;margin-right:0.5rem;") { "✎" }
                button_to "✕", admin_source_tag_path(source_tag), method: :delete, form: { style: "display:inline;" }, style: "background:none;border:none;color:var(--red);cursor:pointer;font:inherit;padding:0;", onclick: "return confirm('Delete this source tag?')"
              end
            end
          end
        end
      end
    else
      div(style: "text-align:center;padding:2rem;") do
        p(class: "text-muted") { "No source tags yet." }
        a(href: new_admin_source_tag_path, class: "btn-success") { "+ New Source Tag" }
      end
    end
  end
end
