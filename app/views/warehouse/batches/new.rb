# frozen_string_literal: true

class Views::Warehouse::Batches::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :available_tags
  register_output_helper :vite_javascript_tag

  def initialize(batch:, allowed_templates:)
    @batch = batch
    @allowed_templates = allowed_templates
  end

  def view_template
    vite_javascript_tag("taggable")

    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: warehouse_batches_path, style: "text-decoration: none; color: var(--foreground2);") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "New Warehouse Batch" }
      end
    end

    error_messages

    div(class: "show-layout") do
      div(class: "show-main") do
        form_with(model: @batch, url: warehouse_batches_path, scope: :batch) do |f|
          div("box-": "round", style: "margin-bottom: 1lh;") do
            strong { "Batch Details" }
            div("is-": "separator")
            div(style: "margin-top: 0.5lh;") do
              div(style: "margin-bottom: 1lh;") do
                label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;", for: "batch_warehouse_template_id") { "Template" }
                select(
                  name: "batch[warehouse_template_id]",
                  id: "batch_warehouse_template_id",
                  style: "width: 100%;",
                  required: true
                ) do
                  @allowed_templates.each do |template|
                    option(value: template.id, selected: template.id == @allowed_templates.first&.id) { template.name }
                  end
                end
              end

              div(style: "margin-bottom: 1lh;") do
                label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Title" }
                input(type: "text", name: "batch[warehouse_user_facing_title]", style: "width: 100%;")
              end
              p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0;") { "Optional — shown on the order list" }
            end
          end

          div("box-": "round", style: "margin-bottom: 1lh;") do
            strong { "Addresses" }
            div("is-": "separator")
            div(style: "margin-top: 0.5lh;") do
              address_fields = Address.column_names - %w[id created_at updated_at batch_id]
              div(
                data_svelte_component: "batch-csv-mapper",
                data_address_fields: address_fields.to_json,
                data_form_field_name: "batch[addresses_data]"
              )
            end
          end

          tag_picker(f)

          row("gap-": "1", "align-": "center", style: "margin-top: 1lh;") do
            a(href: warehouse_batches_path) { "Cancel" }
            button(type: "submit", "variant-": "green") { "✓ Create Batch" }
          end
        end
      end

      div(class: "show-sidebar") do
        div("box-": "round") do
          strong { "Info" }
          div("is-": "separator")
          div(style: "margin-top: 0.5lh; color: var(--foreground2);") do
            p(style: "margin: 0 0 0.5lh;") { "Upload a CSV of addresses, map the columns, and create orders in bulk." }
            p(style: "margin: 0;") { "Each address becomes one warehouse order using the selected template." }
          end
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
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Tags" }
      div("is-": "separator")
      div(style: "margin-top: 0.5lh;") do
        select(
          name: "batch[tags][]",
          multiple: true,
          class: "selectize-tags"
        ) do
          available_tags.each do |tag|
            option(value: tag, selected: @batch.tags&.include?(tag)) { tag }
          end
        end
        p(style: "color: var(--foreground2); font-size: 0.85em; margin: 0;") { "Select from common tags or create your own" }
      end
    end
  end
end
