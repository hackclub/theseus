# frozen_string_literal: true

# CSV column → address field picker. Subclasses supply the routes and copy for
# their batch type.
class Views::Batches::Map < Views::Base
  include Phlex::Rails::Helpers::FormWith

  ADDRESS_FIELDS = [
    [ "", "— skip —" ],
    [ "first_name", "First Name *" ],
    [ "last_name", "Last Name *" ],
    [ "line_1", "Address Line 1 *" ],
    [ "line_2", "Address Line 2" ],
    [ "city", "City *" ],
    [ "state", "State / Province *" ],
    [ "postal_code", "ZIP / Postal Code *" ],
    [ "country", "Country" ],
    [ "email", "Email" ],
    [ "phone_number", "Phone" ]
  ].freeze

  # LetterBatchImporter reads rubber_stamps off the row, so letters need a way
  # to map it. Warehouse orders have nothing to stamp.
  LETTER_ADDRESS_FIELDS = (ADDRESS_FIELDS + [ [ "rubber_stamps", "Rubber Stamps" ] ]).freeze

  # Headers are compared with case, punctuation and spacing thrown away, so
  # "Address (Line 1)", "address_line_1" and "addressline1" are one key.
  def self.normalize_header(header) = header.to_s.downcase.gsub(/[^a-z0-9]/, "")

  # A header with [ or ] in it can't name a form field: rack would read it as a
  # nested hash. BaseBatchesController puts the real header back on the way in.
  def self.param_key(header) = header.to_s.delete("[]")

  AUTO_MAP = {
    "first_name" => "first_name", "first" => "first_name", "fname" => "first_name", "firstname" => "first_name",
    "recipient name" => "first_name", "name" => "first_name",
    "last_name" => "last_name", "last" => "last_name", "lname" => "last_name", "surname" => "last_name",
    "lastname" => "last_name",
    "address" => "line_1", "address_1" => "line_1", "line_1" => "line_1", "street" => "line_1",
    "address_line_1" => "line_1", "street_address" => "line_1", "addressline1" => "line_1",
    "address (line 1)" => "line_1",
    "address_2" => "line_2", "line_2" => "line_2", "apt" => "line_2", "suite" => "line_2",
    "address_line_2" => "line_2", "addressline2" => "line_2", "address (line 2)" => "line_2",
    "city" => "city", "town" => "city", "addresscity" => "city", "address (city)" => "city",
    "state" => "state", "province" => "state", "region" => "state", "state_province" => "state",
    "state / province" => "state", "addressstate" => "state", "address (state/province)" => "state",
    "zip" => "postal_code", "postal_code" => "postal_code", "zipcode" => "postal_code",
    "zip_code" => "postal_code", "postcode" => "postal_code", "zip / postal code" => "postal_code",
    "addresszipcode" => "postal_code", "addresszip" => "postal_code",
    "address (zip/postal code)" => "postal_code",
    "country" => "country", "country_code" => "country", "addresscountry" => "country",
    "address (country)" => "country",
    "email" => "email", "e_mail" => "email", "email_address" => "email", "login email" => "email",
    "phone" => "phone_number", "phone_number" => "phone_number", "tel" => "phone_number",
    "rubber_stamps" => "rubber_stamps", "rubber stamps" => "rubber_stamps"
  }.freeze

  NORMALIZED_AUTO_MAP = AUTO_MAP.transform_keys { |header| normalize_header(header) }.freeze

  def initialize(batch:, csv_headers:, sample_row:)
    @batch = batch
    @csv_headers = csv_headers
    @sample_row = sample_row
  end

  def view_template
    div(class: "flex-row mb-1") do
      a(href: batch_path, class: "link-muted") { "← Batch ##{@batch.public_id}" }
      strong(class: "text-title") { "Map CSV Fields" }
    end

    p(class: "text-muted") do
      plain "Your CSV has #{mappable_headers.length} columns. Map each one to an address field."
    end
    hint
    unmapped_warning

    form_with(url: set_mapping_path, method: :post) do
      table do
        thead do
          tr do
            th { "CSV Column" }
            th { "Sample" }
            th { "Maps to" }
          end
        end
        tbody do
          mappable_headers.each do |header|
            guess = guess_field(header)
            tr do
              td { strong { header } }
              td(class: "text-muted truncate-20ch") do
                plain sample_for(header)
              end
              td do
                select(name: "field_mapping[#{self.class.param_key(header)}]", class: "w-100") do
                  address_fields.each do |value, label|
                    option(value: value, selected: value == guess) { label }
                  end
                end
              end
            end
          end
        end
      end

      hr

      div(class: "flex-row") do
        button(type: "submit", class: "btn-success") { submit_label }
        a(href: batch_path) { "Cancel" }
      end
    end
  end

  private

  def batch_path = raise(NotImplementedError)
  def set_mapping_path = raise(NotImplementedError)
  def submit_label = raise(NotImplementedError)
  def address_fields = @batch.is_a?(::Letter::Batch) ? LETTER_ADDRESS_FIELDS : ADDRESS_FIELDS
  def hint; end

  # A header-only CSV has no sample row at all.
  def sample_for(header) = @sample_row ? @sample_row[header].to_s : ""

  # A blank header would render field_mapping[], which rack refuses to parse
  # alongside the other keys and turns into a 400.
  def mappable_headers = @mappable_headers ||= @csv_headers.compact_blank

  def required_fields = address_fields.select { |_, label| label.end_with?("*") }

  def unmapped_warning
    guessed = mappable_headers.filter_map { |header| guess_field(header) }
    missing = required_fields.reject { |value, _| guessed.include?(value) }
    return if missing.empty?

    div(class: "banner banner-error mb-1") do
      strong { "No column matched these required fields — pick them below:" }
      ul(class: "mt-half") do
        missing.each { |_, label| li { label.delete_suffix("*").strip } }
      end
    end
  end

  def guess_field(header)
    guess = NORMALIZED_AUTO_MAP[self.class.normalize_header(header)]
    guess if address_fields.any? { |value, _| value == guess }
  end
end
