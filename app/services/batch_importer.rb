# frozen_string_literal: true

# Turns a batch's uploaded CSV into Address rows using the header→field map the
# user picked on the Map page. Subclasses decide what else a row becomes (a
# letter, nothing until process time) and which countries are off limits.
class BatchImporter
  # Refusals the batch controllers turn into a flash instead of a 500.
  class Error < StandardError; end
  class AlreadyImported < Error; end
  class NothingToImport < Error; end

  GREMLINS = [ "‎", "​" ].join.freeze

  def initialize(batch)
    @batch = batch
    @mapping = batch.field_mapping&.invert || {}
  end

  def call(skip_invalid: false)
    raise ArgumentError, "no field mapping" if @mapping.blank?
    raise AlreadyImported, "This batch has already been imported." unless @batch.awaiting_field_mapping?

    count = 0

    ActiveRecord::Base.transaction do
      @batch.lock!
      raise AlreadyImported, "This batch has already been imported." unless @batch.awaiting_field_mapping?

      CSV.parse(@batch.csv_data, headers: true).each do |row|
        next if skip_invalid && validate_row(row).any?
        next if get(row, "first_name").blank?

        address = @batch.addresses.create!(build_address(row))
        import_row(row, address)
        count += 1
      end

      raise NothingToImport, "None of the rows in this CSV could be imported." if count.zero?

      @batch.mark_fields_mapped
      @batch.save!
    end

    count
  end

  def validate
    raise ArgumentError, "no field mapping" if @mapping.blank?

    results = []
    CSV.parse(@batch.csv_data, headers: true).each_with_index do |row, i|
      errs = validate_row(row)
      results << {
        row: i,
        status: errs.empty? ? :valid : :error,
        errors: errs,
        sample: get(row, "first_name").to_s + " " + get(row, "last_name").to_s
      }
    end
    results
  end

  private

  # What to do with a row beyond its address. Letters make a Letter here;
  # warehouse batches wait for process time.
  def import_row(row, address); end

  def restricted_countries = Rails.configuration.country_restrictions.usps_restricted

  def restricted_message(country_name) = "USPS doesn't deliver to #{country_name}"

  def validate_row(row)
    errs = []
    errs << "First name blank" if get(row, "first_name").blank?
    errs << "Address blank" if get(row, "line_1").blank?
    errs << "City blank" if get(row, "city").blank?
    errs << "State blank" if get(row, "state").blank?
    zip = get(row, "postal_code")

    raw_country = get(row, "country")
    if raw_country.present? && resolved_country(row).nil?
      # build_address would hand this to the country enum and raise mid-import.
      errs << "Unrecognized country (#{raw_country})"
      errs << "ZIP blank" if zip.blank?
    else
      cc = country_code(row)
      errs << "ZIP blank" if zip.blank? && ISO3166::Country[cc]&.postal_code != false
      # Only the US has a shape we can meaningfully check; "SW1A 2AA" is fine.
      errs << "ZIP looks invalid (#{zip})" if zip.present? && cc == "US" && zip.gsub(/\D/, "").length < 3
      errs << restricted_message(country_name(cc)) if cc.in?(restricted_countries)
    end

    errs
  end

  # Look up a mapped field from the CSV row. Returns nil if unmapped.
  def get(row, field)
    col = @mapping[field]
    return nil if col.blank?
    val = row[col]
    val&.strip&.delete(GREMLINS).presence
  end

  def resolved_country(row)
    raw = get(row, "country")
    return ISO3166::Country["US"] if raw.blank?
    FrickinCountryNames.find_country(raw)
  end

  def country_code(row)
    resolved_country(row)&.alpha2 || get(row, "country").upcase
  end

  def country_name(cc) = ISO3166::Country[cc]&.common_name || cc

  def build_address(row)
    raw_country = get(row, "country")
    country = raw_country.present? ? FrickinCountryNames.find_country(raw_country) : nil
    state = get(row, "state")
    zip = get(row, "postal_code")

    state = FrickinCountryNames.normalize_state(country, state) if country
    zip = zip.rjust(5, "0") if country&.alpha2 == "US" && zip.present? && zip.length < 5

    {
      first_name: get(row, "first_name"),
      last_name: get(row, "last_name"),
      line_1: get(row, "line_1"),
      line_2: get(row, "line_2"),
      city: get(row, "city"),
      state: state,
      postal_code: zip,
      country: country&.alpha2 || raw_country&.upcase || "US",
      phone_number: get(row, "phone_number"),
      email: get(row, "email")
    }
  end
end
