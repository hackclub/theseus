# frozen_string_literal: true

module Letter
  class BatchImporter
    GREMLINS = ["‎", "​"].join.freeze

    def initialize(batch)
      @batch = batch
    end

    def call
      mapping = @batch.field_mapping
      raise ArgumentError, "no field mapping" if mapping.blank?

      count = 0

      CSV.parse(@batch.csv_data, headers: true).each do |row|
        first_name = clean(row[mapping["first_name"]])
        next if first_name.blank?

        address_attrs = extract_address(row, mapping)
        address = @batch.addresses.create!(address_attrs)

        @batch.letters.create!(
          address: address,
          height: @batch.letter_height,
          width: @batch.letter_width,
          weight: @batch.letter_weight,
          processing_category: @batch.letter_processing_category,
          usps_mailer_id: @batch.mailer_id,
          return_address: @batch.letter_return_address,
          return_address_name: @batch.letter_return_address_name,
          recipient_email: clean(row[mapping["email"]]),
          rubber_stamps: clean(row[mapping["rubber_stamps"]]),
          tags: @batch.tags,
          user: @batch.user,
        )

        count += 1
      end

      @batch.mark_fields_mapped unless @batch.fields_mapped? || @batch.processed?
      @batch.save!
      count
    end

    private

    def extract_address(row, mapping)
      raw_country = clean(row[mapping["country"]])
      country = FrickinCountryNames.find_country(raw_country)
      raw_state = clean(row[mapping["state"]])
      raw_zip = clean(row[mapping["postal_code"]])

      state = country ? FrickinCountryNames.normalize_state(country, raw_state) : raw_state

      if country&.alpha2 == "US" && raw_zip.present? && raw_zip.length < 5
        raw_zip = raw_zip.rjust(5, "0")
      end

      {
        first_name: clean(row[mapping["first_name"]]),
        last_name: clean(row[mapping["last_name"]]),
        line_1: clean(row[mapping["line_1"]]),
        line_2: clean(row[mapping["line_2"]]),
        city: clean(row[mapping["city"]]),
        state: state,
        postal_code: raw_zip,
        country: country&.alpha2 || raw_country&.upcase || "US",
        phone_number: clean(row[mapping["phone_number"]]),
        email: clean(row[mapping["email"]]),
      }
    end

    def clean(s)
      s&.strip&.delete(GREMLINS).presence
    end
  end
end
