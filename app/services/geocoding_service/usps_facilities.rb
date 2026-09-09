module GeocodingService
  class USPSFacilities
    class << self
      SPECIAL_CASES = {
        "001376" => {
          lat: "40.6532171",
          lon: "-73.7712486"
        }
      }

      def coords_for_locale_key(locale_key, event = nil)
        SPECIAL_CASES[locale_key] ||
          Rails.cache.fetch("geocode_usps_facility_#{locale_key}", expires_in: 1.day) do
            address = address_for_locale_key(locale_key)
            if address
              GeocodingService.first_hit(address) ||
              GeocodingService.first_hit(address.slice(:city, :state, :postalcode, :country))
            elsif event
              # Fallback to event scan facility data when USPS facility lookup fails
              facility = event.scan_facility
              fallback_address = {
                city: facility[:city],
                state: facility[:state],
                postalcode: facility[:zip],
                country: "US"
              }
              Rails.logger.warn "USPS facility not found for locale_key #{locale_key}, falling back to scan facility data: #{fallback_address}"
              GeocodingService.first_hit(fallback_address)
            else
              nil
            end
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
          country: "US"
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
        xsv.to_a.index_by { |row| row["LOCALE KEY"] }
      end
    end
  end
end
