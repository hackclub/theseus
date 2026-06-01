module USPS
  class PricingEngine
    # this will have to be updated when they come out with a new notice 123!
    FCMI_RATE_TABLE = {
      letter: {
        1.0 => {
          ca: 1.70,
          mx: 1.70,
          other: 1.70
        },
        2.0 => {
          ca: 2.00,
          mx: 2.55,
          other: 3.40
        },
        3.0 => {
          ca: 2.70,
          mx: 3.40,
          other: 5.10
        },
        3.5 => {
          ca: 3.40,
          mx: 4.15,
          other: 5.75
        },
      },
      flat: {
        1.0 => {
          ca: 3.15,
          mx: 3.15,
          other: 3.15
        },
        2.0 => {
          ca: 3.65,
          mx: 4.25,
          other: 4.55
        },
        3.0 => {
          ca: 4.15,
          mx: 5.35,
          other: 5.95
        },
        4.0 => {
          ca: 4.65,
          mx: 6.45,
          other: 7.35
        },
        5.0 => {
          ca: 5.15,
          mx: 7.55,
          other: 8.75
        },
        6.0 => {
          ca: 5.65,
          mx: 8.65,
          other: 10.15
        },
        7.0 => {
          ca: 6.15,
          mx: 9.75,
          other: 11.55
        },
        8.0 => {
          ca: 6.65,
          mx: 10.85,
          other: 12.95
        },
        12.0 => {
          ca: 7.60,
          mx: 13.00,
          other: 15.75
        },
        15.994 => {
          ca: 8.55,
          mx: 15.15,
          other: 18.55
        },
      }
    }
    FCMI_NON_MACHINABLE_SURCHARGE = 0.49

    US_LETTER_RATES = {
      1.0 => 0.74,
      2.0 => 1.03,
      3.0 => 1.32,
      3.5 => 1.61
    }

    US_FLAT_RATES = {
      1.0 => 1.63,
      2.0 => 1.90,
      3.0 => 2.17,
      4.0 => 2.44,
      5.0 => 2.72,
      6.0 => 3.00,
      7.0 => 3.28,
      8.0 => 3.56,
      9.0 => 3.84,
      10.0 => 4.14,
      11.0 => 4.44,
      12.0 => 4.74,
      13.0 => 5.04
    }

    US_STAMP_LETTER_RATES = {
      1.0 => 0.78,
      2.0 => 1.07,
      3.0 => 1.36,
      3.5 => 1.65
    }

    US_STAMP_FLAT_RATES = {
      1.0 => 1.63,
      2.0 => 1.90,
      3.0 => 2.17,
      4.0 => 2.44,
      5.0 => 2.72,
      6.0 => 3.00,
      7.0 => 3.28,
      8.0 => 3.56,
      9.0 => 3.84,
      10.0 => 4.14,
      11.0 => 4.44,
      12.0 => 4.74,
      13.0 => 5.04
    }

    class << self
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
