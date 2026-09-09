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

    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: warehouse_batches_path, class: "link-muted") { "← Batches" }
        strong(class: "text-title") { "New Warehouse Batch" }
      end
    end

render Components::Shared::ErrorMessages.new(record: @batch)

    div(class: "show-layout") do
      div(class: "show-main") do
        form_with(model: @batch, url: warehouse_batches_path, scope: :batch) do |f|
          section(class: "mb-1") do
            strong { "Batch Details" }
            hr
            div(class: "mt-half") do
              div(class: "mb-1") do
                label(class: "label-block text-muted", for: "batch_warehouse_template_id") { "Template" }
                select(
                  name: "batch[warehouse_template_id]",
                  id: "batch_warehouse_template_id",
                  class: "w-100",
                  required: true
                ) do
                  @allowed_templates.each do |template|
                    option(value: template.id, selected: template.id == @allowed_templates.first&.id) { template.name }
                  end
                end
              end

              div(class: "mb-1") do
                label(class: "label-block text-muted") { "Title" }
                input(type: "text", name: "batch[warehouse_user_facing_title]", class: "w-100")
              end
              p(class: "form-field-note") { "Optional — shown on the order list" }
            end
          end

          section(class: "mb-1") do
            strong { "Addresses" }
            hr
            div(class: "mt-half") do
              address_fields = Address.column_names - %w[id created_at updated_at batch_id]
              div(
                data_svelte_component: "batch-csv-mapper",
                data_address_fields: address_fields.to_json,
                data_form_field_name: "batch[addresses_data]"
              )
            end
          end

          tag_picker(f)

          div(class: "batch-new-actions") do
            a(href: warehouse_batches_path) { "Cancel" }
            button(type: "submit", class: "btn-success") { "✓ Create Batch" }
          end
        end
      end

      div(class: "show-sidebar") do
        section do
          strong { "Info" }
          hr
          div(class: "mt-half text-muted") do
            p(class: "batch-new-info-p") { "Upload a CSV of addresses, map the columns, and create orders in bulk." }
            p(class: "m-0") { "Each address becomes one warehouse order using the selected template." }
          end
        end
      end
    end
  end

  private


  def tag_picker(f)
    section(class: "mb-1") do
      strong { "Tags" }
      hr
      div(class: "mt-half") do
        select(
          name: "batch[tags][]",
          multiple: true,
          class: "selectize-tags"
        ) do
          available_tags.each do |tag|
            option(value: tag, selected: @batch.tags&.include?(tag)) { tag }
          end
        end
        p(class: "form-field-note") { "Select from common tags or create your own" }
      end
    end
  end
end
