# frozen_string_literal: true

class Views::Admin::SourceTags::Show < Views::Base
  def initialize(source_tag:)
    @source_tag = source_tag
  end

  def view_template
    div(class: "toolbar", style: "border-bottom:none;margin-bottom:0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem;") do
        a(href: admin_source_tags_path, style: "text-decoration:none;color:GrayText;") { "← Source Tags" }
        strong(style: "font-size:1.15em;") { @source_tag.name }
        span(class: "badge badge-info") { @source_tag.slug }
      end
      div(style: "display:flex;gap:0.5rem;") do
        a(href: edit_admin_source_tag_path(@source_tag), class: "btn-sm") { "Edit" }
        a(
          href: admin_source_tag_path(@source_tag),
          data: { turbo_method: :delete, turbo_confirm: "Delete this source tag?" },
          class: "btn-sm btn-danger"
        ) { "Delete" }
      end
    end

    section do
      strong { "Details" }
      hr

      div(class: "detail-grid") do
        span(class: "detail-label") { "Name" }
        span { @source_tag.name }

        span(class: "detail-label") { "Owner" }
        span { @source_tag.owner.presence || "—" }

        span(class: "detail-label") { "Slug" }
        span do
          span(class: "badge badge-info") { @source_tag.slug }
        end

        span(class: "detail-label") { "Warehouse Orders" }
        span do
          order_count = @source_tag.warehouse_orders.size
          if order_count > 0
            a(href: admin_warehouse_orders_path(source_tag_id: @source_tag.id)) { "#{order_count} orders" }
          else
            plain "0"
          end
        end

        span(class: "detail-label") { "Created" }
        span(class: "text-muted") { @source_tag.created_at.strftime("%b %d, %Y %H:%M") }

        span(class: "detail-label") { "Updated" }
        span(class: "text-muted") { @source_tag.updated_at.strftime("%b %d, %Y %H:%M") }
      end
    end
  end
end
