# frozen_string_literal: true

class Components::Warehouse::SKURequests::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(sku_request:)
    @sku_request = sku_request
  end

  def view_template
    if @sku_request.errors.any?
      div(class: "banner banner-alert", style: "margin-bottom: 1rem;") do
        plain @sku_request.errors.full_messages.to_sentence
      end
    end

    form_with model: @sku_request, url: form_url, local: true do |f|
      div(class: "form-stack") do
        form_field("Name", "warehouse_sku_request[name]", @sku_request.name, required: true)

        form_textarea("Description", "warehouse_sku_request[description]", @sku_request.description)

        category_select

        form_field("Unit Cost", "warehouse_sku_request[unit_cost]", @sku_request.unit_cost,
          required: true, type: "number", hint: "Cost per unit in USD")

        form_field("Country of Origin", "warehouse_sku_request[country_of_origin]", @sku_request.country_of_origin)

        form_field("HS Code", "warehouse_sku_request[hs_code]", @sku_request.hs_code)

        form_textarea("Customs Description", "warehouse_sku_request[customs_description]", @sku_request.customs_description)

        form_field("Program", "warehouse_sku_request[program]", @sku_request.program,
          hint: "e.g. Athena, Stardance, or leave blank")

        form_field("Expected Arrival", "warehouse_sku_request[expected_arrival]",
          @sku_request.expected_arrival&.to_s, type: "date")

        form_field("Expected Quantity", "warehouse_sku_request[expected_quantity]",
          @sku_request.expected_quantity, type: "number")

        form_field("Suggested SKU Code", "warehouse_sku_request[suggested_sku_code]",
          @sku_request.suggested_sku_code, hint: "We'll auto-suggest if blank")

        image_field

        div(style: "padding-top:1rem;") do
          button(type: "submit", class: "btn-success") do
            plain(@sku_request.persisted? ? "Update SKU Request" : "Create SKU Request")
          end
        end
      end
    end
  end

  private

  def form_url
    @sku_request.persisted? ? warehouse_sku_request_path(@sku_request) : warehouse_sku_requests_path
  end

  def form_field(label_text, name, value, required: false, type: "text", hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") do
        plain label_text
        plain " *" if required
      end
      attrs = { type: type, name: name, value: value, required: required, style: "width:100%;" }
      attrs[:step] = "0.01" if type == "number"
      input(**attrs)
      if hint
        small(class: "text-muted", style: "display:block;") { hint }
      end
    end
  end

  def form_textarea(label_text, name, value, hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") { label_text }
      textarea(name: name, rows: 3, style: "width:100%;") { value }
      if hint
        small(class: "text-muted", style: "display:block;") { hint }
      end
    end
  end

  def category_select
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") do
        plain "Category"
        plain " *"
      end
      select(name: "warehouse_sku_request[category]", required: true, style: "width:100%;") do
        option(value: "") { "Select a category..." }
        ::Warehouse::SKU.categories.keys.each do |cat|
          if @sku_request.category == cat
            option(value: cat, selected: true) { cat.humanize }
          else
            option(value: cat) { cat.humanize }
          end
        end
      end
    end
  end

  def image_field
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") { "Image" }
      input(type: "file", name: "warehouse_sku_request[image]", accept: "image/*")
      if @sku_request.persisted? && @sku_request.image.attached?
        small(class: "text-muted", style: "display:block;") { "Current image attached. Upload a new one to replace." }
      end
    end
  end
end
