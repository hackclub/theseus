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
        form_field("Name", "warehouse_sku_request[name]", @sku_request.name,
          required: true, hint: "What is this item?")

        form_textarea("Description", "warehouse_sku_request[description]", @sku_request.description,
          required: true, hint: "One or two sentences describing the item")

        category_select

        form_field("Unit Cost", "warehouse_sku_request[unit_cost]", @sku_request.unit_cost,
          required: true, type: "number", hint: "Purchase price of ONE item in USD")

        form_field("Country of Origin", "warehouse_sku_request[country_of_origin]", @sku_request.country_of_origin,
          required: true, hint: "Where was this manufactured?")

        form_field("Program", "warehouse_sku_request[program]", @sku_request.program,
          required: true, hint: "e.g. Athena, Stardance, Brand, HCB")

        form_field("Expected Arrival", "warehouse_sku_request[expected_arrival]",
          @sku_request.expected_arrival&.to_s, required: true, type: "date",
          hint: "When will these arrive at the warehouse?")

        form_field("Expected Quantity", "warehouse_sku_request[expected_quantity]",
          @sku_request.expected_quantity, required: true, type: "number",
          hint: "How many items are being delivered?")

        image_field

        hr

        form_field("HS Code", "warehouse_sku_request[hs_code]", @sku_request.hs_code,
          hint: "Harmonized System code for customs (optional, czar can fill in)")

        form_textarea("Customs Description", "warehouse_sku_request[customs_description]", @sku_request.customs_description,
          hint: "Brief description for customs forms (optional, czar can fill in)")

        form_field("Suggested SKU Code", "warehouse_sku_request[suggested_sku_code]",
          @sku_request.suggested_sku_code, hint: "Optional — czar will assign the final code")

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
      coerced_value = value.is_a?(BigDecimal) ? "%.2f" % value : value
      attrs = { type: type, name: name, value: coerced_value, required: required, style: "width:100%;" }
      attrs[:step] = "0.01" if type == "number"
      input(**attrs)
      if hint
        small(class: "text-muted", style: "display:block;") { hint }
      end
    end
  end

  def form_textarea(label_text, name, value, required: false, hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") do
        plain label_text
        plain " *" if required
      end
      textarea(name: name, rows: 3, required: required, style: "width:100%;") { value }
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
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") do
        plain "Photo of the item"
        plain " *"
      end
      input(type: "file", name: "warehouse_sku_request[image]", accept: "image/png,image/jpeg,image/gif,image/webp", required: !@sku_request.image.attached?)
      small(class: "text-muted", style: "display:block;") do
        if @sku_request.persisted? && @sku_request.image.attached?
          plain "Current image attached. Upload a new one to replace."
        else
          plain "Required — this will be uploaded to Zenventory by the czar"
        end
      end
    end
  end
end
