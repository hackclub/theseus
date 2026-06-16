# frozen_string_literal: true

class Views::Warehouse::Batches::Edit < Views::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :available_tags
  register_output_helper :vite_javascript_tag

  def initialize(batch:, allowed_templates: [])
    @batch = batch
    @allowed_templates = allowed_templates
  end

  def view_template
    vite_javascript_tag("taggable")

    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: warehouse_batch_path(@batch), style: "text-decoration: none; color: GrayText;") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Edit Warehouse Batch" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
    end

    error_messages

    div(class: "show-layout") do
      div(class: "show-main") do
        form_with(model: @batch, url: warehouse_batch_path(@batch), scope: :batch, method: :patch) do |f|
          section(style: "margin-bottom: 1rem;") do
            strong { "Batch Details" }
            hr
            div(style: "margin-top: 0.5rem;") do
              if @allowed_templates.any?
                div(style: "margin-bottom: 1rem;") do
                  label(style: "display: block; color: GrayText; margin-bottom: 0.25rem;", for: "batch_warehouse_template_id") { "Template" }
                  select(
                    name: "batch[warehouse_template_id]",
                    id: "batch_warehouse_template_id",
                    style: "width: 100%;"
                  ) do
                    @allowed_templates.each do |template|
                      option(value: template.id, selected: template.id == @batch.warehouse_template_id) { template.name }
                    end
                  end
                end
              end

              div(style: "margin-bottom: 1rem;") do
                label(style: "display: block; color: GrayText; margin-bottom: 0.25rem;") { "Title" }
                input(type: "text", name: "batch[warehouse_user_facing_title]", value: @batch.warehouse_user_facing_title, style: "width: 100%;")
              end
            end
          end

          tag_picker(f)

          div(style: "display:flex;align-items:center;gap:0.5rem;margin-top:1rem") do
            a(href: warehouse_batch_path(@batch)) { "Cancel" }
            button(type: "submit", class: "btn-success") { "✓ Update Batch" }
          end
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "Batch Info" }
          hr
          div(class: "detail-grid", style: "margin-top: 0.5rem;") do
            span(class: "detail-label") { "ID" }
            span { "##{@batch.id}" }
            span(class: "detail-label") { "Created" }
            span { @batch.created_at.strftime("%b %d, %Y") }
            span(class: "detail-label") { "Addresses" }
            span { @batch.addresses.count.to_s }
            span(class: "detail-label") { "Orders" }
            span { @batch.orders.count.to_s }
          end
        end
      end
    end
  end

  private

  def error_messages
    return unless @batch.errors.any?

    div(class: "banner banner-error", style: "margin-bottom: 1rem;") do
      strong { "[!] Hey, slight issue:" }
      ul(class: "error-list") do
        @batch.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def tag_picker(f)
    section(style: "margin-bottom: 1rem;") do
      strong { "Tags" }
      hr
      div(style: "margin-top: 0.5rem;") do
        select(
          name: "batch[tags][]",
          multiple: true,
          class: "selectize-tags"
        ) do
          available_tags.each do |tag|
            option(value: tag, selected: @batch.tags&.include?(tag)) { tag }
          end
        end
        p(style: "color: GrayText; font-size: 0.85em; margin: 0;") { "Select from common tags or create your own" }
      end
    end
  end
end
