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
        render Components::Shared::FormField.new(label: "Name", name: "warehouse_sku_request[name]", value: @sku_request.name,
          required: true, hint: "What is this item?")

        render Components::Shared::FormField.new(label: "Description", required: true, hint: "One or two sentences describing the item", input: false) do
          textarea(name: "warehouse_sku_request[description]", rows: 3, required: true, class: "form-field-input") { @sku_request.description }
        end

        category_select

        render Components::Shared::FormField.new(label: "Unit Cost", name: "warehouse_sku_request[unit_cost]", value: @sku_request.unit_cost,
          required: true, type: "number", hint: "Purchase price of ONE item in USD")

        render Components::Shared::FormField.new(label: "Country of Origin", name: "warehouse_sku_request[country_of_origin]", value: @sku_request.country_of_origin,
          required: true, hint: "Where was this manufactured?")

        render Components::Shared::FormField.new(label: "Program", name: "warehouse_sku_request[program]", value: @sku_request.program,
          required: true, hint: "e.g. Athena, Stardance, Brand, HCB")

        render Components::Shared::FormField.new(label: "Expected Arrival", name: "warehouse_sku_request[expected_arrival]",
          value: @sku_request.expected_arrival&.to_s, required: true, type: "date",
          hint: "When will these arrive at the warehouse?")

        render Components::Shared::FormField.new(label: "Expected Quantity", name: "warehouse_sku_request[expected_quantity]",
          value: @sku_request.expected_quantity, required: true, type: "number",
          hint: "How many items are being delivered?")

        image_field

        hr

        render Components::Shared::FormField.new(label: "HS Code", name: "warehouse_sku_request[hs_code]", value: @sku_request.hs_code,
          hint: "Harmonized System code for customs (optional, czar can fill in)")

        render Components::Shared::FormField.new(label: "Customs Description", hint: "Brief description for customs forms (optional, czar can fill in)", input: false) do
          textarea(name: "warehouse_sku_request[customs_description]", rows: 3, class: "form-field-input") { @sku_request.customs_description }
        end

        render Components::Shared::FormField.new(label: "Suggested SKU Code", name: "warehouse_sku_request[suggested_sku_code]",
          value: @sku_request.suggested_sku_code, hint: "Optional — czar will assign the final code")

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
