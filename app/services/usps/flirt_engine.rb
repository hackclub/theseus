module USPS
  # First-Class Letter Inverse Rating Toolkit
  class FLIRTEngine
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

      # calculate the retail FCMI price for a :letter or a :flat going to a given country
      def desired_price(type, weight, country, non_machinable = false)
        type = type.to_sym
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

      # Calculate the metered rate for a US letter or flat
      # @param type [Symbol] :letter or :flat
      # @param weight [Float] weight in ounces
      # @param non_machinable [Boolean] whether the item is non-machinable (only valid for letters)
      # @return [Float] the metered rate price
      def metered_price(type, weight, non_machinable = false)
        type = type.to_sym
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

      # Calculate the stamp rate for a US letter or flat
      # @param type [Symbol] :letter or :flat
      # @param weight [Float] weight in ounces
      # @param non_machinable [Boolean] whether the item is non-machinable (only valid for letters)
      # @return [Float] the stamp rate price
      def stamp_price(type, weight, non_machinable = false)
        type = type.to_sym
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

      def closest_us_price(fcmi_rate)
        best_option = nil
        best_price = Float::INFINITY

        US_LETTER_RATES.each do |weight, price|
          [ false, true ].each do |non_machinable|
            adjusted_price = price + (non_machinable ? FCMI_NON_MACHINABLE_SURCHARGE : 0)
            if adjusted_price >= fcmi_rate && adjusted_price < best_price
              best_price = adjusted_price
              best_option = {
                processing_category: :letter,
                weight: weight,
                non_machinable: non_machinable
              }
            end
          end
        end

        US_FLAT_RATES.each do |weight, price|
          if price >= fcmi_rate && price < best_price
            best_price = price
            best_option = {
              processing_category: :flat,
              weight: weight,
              non_machinable: false
            }
          end
        end

        raise ArgumentError, "can't figure out how to make $#{fcmi_rate} out of US rates, gotta use stamps instead :-(" unless best_option
        best_option.merge(difference: best_price - fcmi_rate, price: best_price)
      end
    end
  end
end
