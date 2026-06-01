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
        render Primer::Beta::Button.new(tag: :a, href: warehouse_batch_path(@batch), scheme: :invisible, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back"
        end
        h1(class: "page-title") { "Edit Warehouse Batch ##{@batch.id}" }
      end

      error_messages

      form_with(model: @batch, url: warehouse_batch_path(@batch), scope: :batch, method: :patch) do |f|
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h2) { "Batch Details" }
          end
          box.with_body do
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

            render Primer::Alpha::TextField.new(
              name: "batch[warehouse_user_facing_title]",
              label: "Title",
              value: @batch.warehouse_user_facing_title,
              full_width: true,
              mb: 3
            )
          end
        end

        # Tags
        tag_picker(f)

        div(class: "page-actions") do
          render Primer::Beta::Button.new(tag: :a, href: warehouse_batch_path(@batch), scheme: :secondary) do
            "Cancel"
          end
          render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :check)
            "Update Batch"
          end
        end
      end
    end
  end

  private

  def error_messages
    return unless @batch.errors.any?

    render Primer::Beta::Flash.new(scheme: :danger, mb: 3) do
      strong { "Hey, slight issue:" }
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
