module GeocodingService
  class USPSFacilities
    class << self
      SPECIAL_CASES = {
        "001376" => {
          lat: "40.6532171",
          lon: "-73.7712486",
        },
      }

      def coords_for_locale_key(locale_key)
        SPECIAL_CASES[locale_key] ||
          Rails.cache.fetch("geocode_usps_facility_#{locale_key}", expires_in: 1.day) do
            GeocodingService.first_hit(address_for_locale_key(locale_key)) ||
            GeocodingService.first_hit(address_for_locale_key(locale_key).slice(:city, :state, :postalcode, :country))
          end
      end

      def address_for_locale_key(locale_key)
        facility = find_facility(locale_key)
        return nil unless facility

        {
          street: facility["FACILITY ADDRESS"],
          city: facility["FACILITY CITY"],
          state: facility["FACILITY STATE"],
          postalcode: facility["ZIP"][0...5],
          country: "US",
        }
      end

      def find_facility(locale_key)
        facilities[locale_key]
      end

      private

      def facilities
        @facilities ||= load_facilities
      end

      def load_facilities
        Rails.logger.info "Loading USPS facilities"
        facilities_file = File.join(File.dirname(__FILE__), "FACILITY.xlsx")
        xsv = Xsv.open(facilities_file, parse_headers: true).first
        return xsv.to_a.index_by { |row| row["LOCALE KEY"] }
      end
    end
  end
end
