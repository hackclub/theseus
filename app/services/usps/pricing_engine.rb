module USPS
  class PricingEngine
    class << self
      # Updated for USPS Notice 123 - 2024 rate changes
      FCMI_RATE_TABLE = {
        letter: {
          1.0 => {
            ca: 1.75,
            mx: 1.75,
            other: 1.75
          },
          2.0 => {
            ca: 1.75,
            mx: 2.65,
            other: 3.16
          },
          3.0 => {
            ca: 2.50,
            mx: 3.50,
            other: 4.62
          },
          3.5 => {
            ca: 3.20,
            mx: 4.39,
            other: 6.09
          }
        },
        flat: {
          1.0 => {
            ca: 3.34,
            mx: 3.34,
            other: 3.34
          },
          2.0 => {
            ca: 3.76,
            mx: 4.47,
            other: 4.75
          },
          3.0 => {
            ca: 4.09,
            mx: 5.47,
            other: 6.13
          },
          4.0 => {
            ca: 4.37,
            mx: 6.50,
            other: 7.54
          },
          5.0 => {
            ca: 4.70,
            mx: 7.52,
            other: 8.92
          },
          6.0 => {
            ca: 5.02,
            mx: 8.51,
            other: 10.30
          },
          7.0 => {
            ca: 5.32,
            mx: 9.55,
            other: 11.67
          },
          8.0 => {
            ca: 5.64,
            mx: 10.56,
            other: 13.05
          },
          12.0 => {
            ca: 7.20,
            mx: 12.75,
            other: 15.82
          },
          15.994 => {
            ca: 8.77,
            mx: 14.95,
            other: 18.59
          }
        }
      }
      FCMI_NON_MACHINABLE_SURCHARGE = 0.48

      US_LETTER_RATES = {
        1.0 => 0.73,
        2.0 => 1.02,
        3.0 => 1.31,
        3.5 => 1.60
      }

      US_FLAT_RATES = {
        1.0 => 1.55,
        2.0 => 1.83,
        3.0 => 2.11,
        4.0 => 2.39,
        5.0 => 2.68,
        6.0 => 2.97,
        7.0 => 3.26,
        8.0 => 3.55,
        9.0 => 3.84,
        10.0 => 4.15,
        11.0 => 4.46,
        12.0 => 4.77,
        13.0 => 5.08
      }

      US_STAMP_LETTER_RATES = {
        1.0 => 0.78,
        2.0 => 1.08,
        3.0 => 1.38,
        3.5 => 1.68
      }

      US_STAMP_FLAT_RATES = {
        1.0 => 1.55,
        2.0 => 1.83,
        3.0 => 2.11,
        4.0 => 2.39,
        5.0 => 2.68,
        6.0 => 2.97,
        7.0 => 3.26,
        8.0 => 3.55,
        9.0 => 3.84,
        10.0 => 4.15,
        11.0 => 4.46,
        12.0 => 4.77,
        13.0 => 5.08
      }

      def metered_price(processing_category, weight, non_machinable = false)
        type = processing_category.to_sym
        rates = case type
        when :letter
                  US_LETTER_RATES
        when :flat
                  US_FLAT_RATES
        else
                  raise ArgumentError, "type must be :letter or :flat"
        end

        rate = rates.find { |k, v| weight <= k }&.last
        raise ArgumentError, "#{weight} oz is too heavy for a #{type}" unless rate

        if non_machinable
          raise ArgumentError, "only letters can be non-machinable!" unless type == :letter
          rate += FCMI_NON_MACHINABLE_SURCHARGE
        end

        rate
      end

      def domestic_stamp_price(processing_category, weight, non_machinable = false)
        type = processing_category.to_sym
        rates = case type
        when :letter
                  US_STAMP_LETTER_RATES
        when :flat
                  US_STAMP_FLAT_RATES
        else
                  raise ArgumentError, "type must be :letter or :flat"
        end

        rate = rates.find { |k, v| weight <= k }&.last
        raise ArgumentError, "#{weight} oz is too heavy for a #{type}" unless rate

        if non_machinable
          raise ArgumentError, "only letters can be non-machinable!" unless type == :letter
          rate += FCMI_NON_MACHINABLE_SURCHARGE
        end

        rate
      end

      def fcmi_price(processing_category, weight, country, non_machinable = false)
        type = processing_category.to_sym
        rates = FCMI_RATE_TABLE[type]

        raise ArgumentError, "idk the rates for #{type}..." unless rates
        country = case country
        when "CA"
                    :ca
        when "MX"
                    :mx
        else
                    :other
        end

        rate = rates.find { |k, v| weight <= k }&.dig(1)
        raise "#{weight} oz is too heavy for an FCMI #{type}" unless rate
        price = rate[country]
        if non_machinable
          raise ArgumentError, "only letters can be nonmachinable!" unless type == :letter
          price += FCMI_NON_MACHINABLE_SURCHARGE
        end
        price
      end

      def stamp_price(processing_category, weight, country, non_machinable = false)
        if country == "US"
          domestic_stamp_price(processing_category, weight, non_machinable)
        else
          fcmi_price(processing_category, weight, country, non_machinable)
        end
      end
    end
  end
end
