# frozen_string_literal: true

class LetterBatchImporter
  GREMLINS = ["‎", "​"].join.freeze

  def initialize(batch)
    @batch = batch
    @mapping = batch.field_mapping&.invert || {}
  end

  def call(skip_invalid: false)
    raise ArgumentError, "no field mapping" if @mapping.blank?

    count = 0

    CSV.parse(@batch.csv_data, headers: true).each do |row|
      if skip_invalid
        next if validate_row(row).any?
      end

      first_name = get(row, "first_name")
      next if first_name.blank?

      address = @batch.addresses.create!(build_address(row))

      @batch.letters.create!(
        address: address,
        height: @batch.letter_height,
        width: @batch.letter_width,
        weight: @batch.letter_weight,
        processing_category: @batch.letter_processing_category,
        usps_mailer_id: @batch.mailer_id,
        return_address: @batch.letter_return_address,
        return_address_name: @batch.letter_return_address_name,
        recipient_email: get(row, "email"),
        rubber_stamps: get(row, "rubber_stamps"),
        tags: @batch.tags,
        user: @batch.user,
      )

      count += 1
    end

    @batch.mark_fields_mapped unless @batch.fields_mapped? || @batch.processed?
    @batch.save!
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
        sample: get(row, "first_name").to_s + " " + get(row, "last_name").to_s,
      }
    end
    results
  end

  private

  def validate_row(row)
    errs = []
    errs << "First name blank" if get(row, "first_name").blank?
    errs << "Address blank" if get(row, "line_1").blank?
    errs << "City blank" if get(row, "city").blank?
    errs << "State blank" if get(row, "state").blank?
    zip = get(row, "postal_code")
    errs << "ZIP blank" if zip.blank?
    errs << "ZIP looks invalid (#{zip})" if zip.present? && zip.gsub(/\D/, "").length < 3
    errs
  end

  # Look up a mapped field from the CSV row. Returns nil if unmapped.
  def get(row, field)
    col = @mapping[field]
    return nil if col.blank?
    val = row[col]
    val&.strip&.delete(GREMLINS).presence
  end

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
      email: get(row, "email"),
    }
  end
end
