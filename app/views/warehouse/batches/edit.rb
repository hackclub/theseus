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

    div(class: "page-container") do
      div(class: "page-title-group mb-3") do
        a(href: warehouse_batch_path(@batch), "size-": "small") { "← Back" }
        h1(class: "page-title") { "Edit Warehouse Batch ##{@batch.id}" }
      end

      error_messages

      form_with(model: @batch, url: warehouse_batch_path(@batch), scope: :batch, method: :patch) do |f|
        div("box-": "round", style: "margin-bottom: 2lh;") do
          h2(style: "margin: 0;") { "Batch Details" }
          div("is-": "separator")
          div(style: "padding: 1lh 0;") do
            if @allowed_templates.any?
              div(class: "form-field-lg") do
                label(class: "date-field-label", for: "batch_warehouse_template_id") { "Template" }
                div(class: "mt-1") do
                  select(
                    name: "batch[warehouse_template_id]",
                    id: "batch_warehouse_template_id",
                    class: "select-field"
                  ) do
                    @allowed_templates.each do |template|
                      option(value: template.id, selected: template.id == @batch.warehouse_template_id) { template.name }
                    end
                  end
                end
              end
            end

            div(style: "margin-bottom: 1lh;") do
              label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Title" }
              input(type: "text", name: "batch[warehouse_user_facing_title]", value: @batch.warehouse_user_facing_title, style: "width: 100%;")
            end
          end
        end

        # Tags
        tag_picker(f)

        div(class: "page-actions") do
          a(href: warehouse_batch_path(@batch)) { "Cancel" }
          button(type: "submit", "variant-": "green") { "✓ Update Batch" }
        end
      end
    end
  end

  private

  def error_messages
    return unless @batch.errors.any?

    div("box-": "square", class: "tui-banner tui-banner-error", style: "margin-bottom: 1lh;") do
      strong { "[!] Hey, slight issue:" }
      ul(class: "error-list") do
        @batch.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def tag_picker(f)
    div(class: "form-field-lg") do
      label(class: "date-field-label") { "Tags" }
      select(
        name: "batch[tags][]",
        multiple: true,
        class: "selectize-tags"
      ) do
        available_tags.each do |tag|
          option(value: tag, selected: @batch.tags&.include?(tag)) { tag }
        end
      end
      p(class: "form-hint") { "Select from common tags or create your own" }
    end
  end
end
