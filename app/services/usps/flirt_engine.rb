module USPS
  # First-Class Letter Inverse Rating Toolkit
  class FLIRTEngine
    class << self
      # this will have to be updated when they come out with a new notice 123!
      FCMI_RATE_TABLE = {
        letter: {
          1.0 => {
            ca: 1.65,
            mx: 1.65,
            other: 1.65
          },
          2.0 => {
            ca: 1.65,
            mx: 2.50,
            other: 2.98
          },
          3.0 => {
            ca: 2.36,
            mx: 3.30,
            other: 4.36
          },
          3.5 => {
            ca: 3.02,
            mx: 4.14,
            other: 5.75
          }
        },
        flat: {
          1.0 => {
            ca: 3.15,
            mx: 3.15,
            other: 3.15
          },
          2.0 => {
            ca: 3.55,
            mx: 4.22,
            other: 4.48
          },
          3.0 => {
            ca: 3.86,
            mx: 5.16,
            other: 5.78
          },
          4.0 => {
            ca: 4.12,
            mx: 6.13,
            other: 7.11
          },
          5.0 => {
            ca: 4.43,
            mx: 7.09,
            other: 8.41
          },
          6.0 => {
            ca: 4.73,
            mx: 8.03,
            other: 9.71
          },
          7.0 => {
            ca: 5.02,
            mx: 9.01,
            other: 11.01
          },
          8.0 => {
            ca: 5.32,
            mx: 9.96,
            other: 12.31
          },
          12.0 => {
            ca: 6.79,
            mx: 12.03,
            other: 14.92
          },
          15.994 => {
            ca: 8.27,
            mx: 14.10,
            other: 17.53
          }
        }
      }
      FCMI_NON_MACHINABLE_SURCHARGE = 0.46

      US_LETTER_RATES = {
        1.0 => 0.69,
        2.0 => 0.97,
        3.0 => 1.25,
        3.5 => 1.53
      }

      US_FLAT_RATES = {
        1.0 => 1.50,
        2.0 => 1.77,
        3.0 => 2.04,
        4.0 => 2.31,
        5.0 => 2.59,
        6.0 => 2.87,
        7.0 => 3.15,
        8.0 => 3.43,
        9.0 => 3.71,
        10.0 => 4.01,
        11.0 => 4.31,
        12.0 => 4.61,
        13.0 => 4.91
      }

      US_STAMP_LETTER_RATES = {
        1.0 => 0.73,
        2.0 => 1.01,
        3.0 => 1.29,
        3.5 => 1.57
      }

      US_STAMP_FLAT_RATES = {
        1.0 => 1.50,
        2.0 => 1.77,
        3.0 => 2.04,
        4.0 => 2.31,
        5.0 => 2.59,
        6.0 => 2.87,
        7.0 => 3.15,
        8.0 => 3.43,
        9.0 => 3.71,
        10.0 => 4.01,
        11.0 => 4.31,
        12.0 => 4.61,
        13.0 => 4.91
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
