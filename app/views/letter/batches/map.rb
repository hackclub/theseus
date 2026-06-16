# frozen_string_literal: true

class Views::Letter::Batches::Map < Views::Base
  ADDRESS_FIELDS = [
    ["", "— skip —"],
    ["first_name", "First Name *"],
    ["last_name", "Last Name *"],
    ["line_1", "Address Line 1 *"],
    ["line_2", "Address Line 2"],
    ["city", "City *"],
    ["state", "State / Province *"],
    ["postal_code", "ZIP / Postal Code *"],
    ["country", "Country"],
    ["email", "Email"],
    ["phone_number", "Phone"],
  ].freeze

  REQUIRED = %w[first_name last_name line_1 city state postal_code].freeze

  AUTO_MAP = {
    "first_name" => "first_name", "first" => "first_name", "fname" => "first_name",
    "last_name" => "last_name", "last" => "last_name", "lname" => "last_name", "surname" => "last_name",
    "address" => "line_1", "address_1" => "line_1", "line_1" => "line_1", "street" => "line_1", "address_line_1" => "line_1", "street_address" => "line_1",
    "address_2" => "line_2", "line_2" => "line_2", "apt" => "line_2", "suite" => "line_2", "address_line_2" => "line_2",
    "city" => "city", "town" => "city",
    "state" => "state", "province" => "state", "region" => "state", "state_province" => "state",
    "zip" => "postal_code", "postal_code" => "postal_code", "zipcode" => "postal_code", "zip_code" => "postal_code", "postcode" => "postal_code",
    "country" => "country", "country_code" => "country",
    "email" => "email", "e_mail" => "email", "email_address" => "email",
    "phone" => "phone_number", "phone_number" => "phone_number", "tel" => "phone_number",
  }.freeze

  def initialize(batch:, csv_headers:, sample_row:)
    @batch = batch
    @csv_headers = csv_headers
    @sample_row = sample_row
  end

  def view_template
    div(style: "display:flex;align-items:center;gap:0.5rem;margin-bottom:1rem;") do
      a(href: letter_batch_path(@batch), style: "text-decoration:none;color:GrayText;") { "← Batch ##{@batch.public_id}" }
      strong(style: "font-size:1.15em;") { "Map CSV Fields" }
    end

    p(class: "text-muted") do
      plain "Your CSV has #{@csv_headers.length} columns. Map each one to an address field."
    end

    form_with(url: set_mapping_letter_batch_path(@batch), method: :post) do
      table do
        thead do
          tr do
            th { "CSV Column" }
            th { "Sample" }
            th { "Maps to" }
          end
        end
        tbody do
          @csv_headers.each do |header|
            guess = guess_field(header)
            tr do
              td { strong { header } }
              td(class: "text-muted", style: "max-width:20ch;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;") do
                plain @sample_row[header].to_s
              end
              td do
                select(name: "field_mapping[#{header}]", style: "width:100%;") do
                  ADDRESS_FIELDS.each do |value, label|
                    if value == guess
                      option(value: value, selected: true) { label }
                    else
                      option(value: value) { label }
                    end
                  end
                end
              end
            end
          end
        end
      end

      hr

      div(style: "display:flex;align-items:center;gap:0.5rem;") do
        button(type: "submit", class: "btn-success") { "✓ Map & Create Letters" }
        a(href: letter_batch_path(@batch)) { "Cancel" }
      end
    end
  end

  private

  def guess_field(header)
    normalized = header.to_s.strip.downcase.gsub(/[\s\-]+/, "_")
    AUTO_MAP[normalized]
  end
end
