namespace :usps do
  desc "Fetch latest USPS postage rates and regenerate pricing_engine.rb"
  task update_rates: :environment do
    puts "Fetching USPS rates..."

    # Weight breakpoints for each category
    letter_weights = [1.0, 2.0, 3.0, 3.5]
    flat_weights = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0]
    fcmi_letter_weights = [1.0, 2.0, 3.0, 3.5]
    fcmi_flat_weights = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 12.0, 15.994]

    # Countries for FCMI rate groups
    fcmi_countries = { ca: "CA", mx: "MX", other: "GB" }

    # Fetch domestic rates (the letter-rates API returns both metered and stamp prices)
    puts "  Fetching domestic letter rates..."
    us_letter_rates = fetch_domestic_rates("LETTERS", letter_weights)

    puts "  Fetching domestic flat rates..."
    us_flat_rates = fetch_domestic_rates("FLATS", flat_weights)

    # For stamp rates, we use the same endpoint - USPS letter-rates returns retail prices
    # which are the same as stamp prices
    us_stamp_letter_rates = us_letter_rates.dup
    us_stamp_flat_rates = us_flat_rates.dup

    # Fetch FCMI rates
    puts "  Fetching FCMI letter rates..."
    fcmi_letter_rates = fetch_fcmi_rates("LETTERS", fcmi_letter_weights, fcmi_countries)

    puts "  Fetching FCMI flat rates..."
    fcmi_flat_rates = fetch_fcmi_rates("FLATS", fcmi_flat_weights, fcmi_countries)

    # Fetch non-machinable surcharges
    puts "  Fetching domestic non-machinable surcharge..."
    domestic_nm_surcharge = fetch_domestic_non_machinable_surcharge
    puts "  Fetching international non-machinable surcharge..."
    intl_nm_surcharge = fetch_international_non_machinable_surcharge

    # Use the higher of the two (they should be the same, but just in case)
    nm_surcharge = [domestic_nm_surcharge, intl_nm_surcharge].max
    puts "  Using non-machinable surcharge: $#{nm_surcharge}"

    puts "Generating pricing_engine.rb..."
    generate_pricing_engine(
      fcmi_letter_rates: fcmi_letter_rates,
      fcmi_flat_rates: fcmi_flat_rates,
      fcmi_nm_surcharge: nm_surcharge,
      us_letter_rates: us_letter_rates,
      us_flat_rates: us_flat_rates,
      us_stamp_letter_rates: us_stamp_letter_rates,
      us_stamp_flat_rates: us_stamp_flat_rates
    )

    puts "Done! Updated app/services/usps/pricing_engine.rb"
  end

  def fetch_domestic_rates(processing_category, weights, non_machinable: false)
    rates = {}
    nm_indicators = non_machinable ? { isRigid: true } : {}
    weights.each do |weight|
      response = USPS::APIService.letter_price(
        processing_category: processing_category,
        weight: weight,
        non_machinable_indicators: nm_indicators
      )
      price = response.dig(:rates, 0, :price) || response.dig(:totalBasePrice)
      rates[weight] = price.to_f
      print "."
    end
    puts
    rates
  end

  def fetch_fcmi_rates(processing_category, weights, countries)
    rates = {}
    weights.each do |weight|
      rates[weight] = {}
      countries.each do |key, country_code|
        response = USPS::APIService.international_letter_price(
          processing_category: processing_category,
          weight: weight,
          destination_country_code: country_code
        )
        price = response.dig(:rates, 0, :price) || response.dig(:totalBasePrice)
        rates[weight][key] = price.to_f
        print "."
      end
    end
    puts
    rates
  end

  def fetch_domestic_non_machinable_surcharge
    response = USPS::APIService.letter_price(
      processing_category: "LETTERS",
      weight: 1.0,
      non_machinable_indicators: { isRigid: true }
    )
    extract_nm_surcharge(response, "domestic")
  end

  def fetch_international_non_machinable_surcharge
    response = USPS::APIService.international_letter_price(
      processing_category: "LETTERS",
      weight: 1.0,
      destination_country_code: "GB"
    )
    # International API may not have NM indicators, so we compare with a machinable request
    # or look for fees in response
    extract_nm_surcharge(response, "international")
  end

  def extract_nm_surcharge(response, label)
    fees = response.dig(:rates, 0, :fees) || []
    nm_fee = fees.find { |f| f[:name]&.downcase&.include?("nonmachinable") }

    if nm_fee
      puts "    (#{label}: from API fees: $#{nm_fee[:price]})"
      nm_fee[:price].to_f
    else
      total = response[:totalBasePrice].to_f
      base = response.dig(:rates, 0, :price).to_f
      diff = (total - base).round(2)
      if diff.positive?
        puts "    (#{label}: calculated from price difference: $#{diff})"
        diff
      else
        puts "    (#{label}: using fallback value: $0.46)"
        0.46
      end
    end
  end

  def generate_pricing_engine(
    fcmi_letter_rates:,
    fcmi_flat_rates:,
    fcmi_nm_surcharge:,
    us_letter_rates:,
    us_flat_rates:,
    us_stamp_letter_rates:,
    us_stamp_flat_rates:
  )
    content = <<~RUBY
      module USPS
        class PricingEngine
          # this will have to be updated when they come out with a new notice 123!
          FCMI_RATE_TABLE = {
            letter: {
      #{format_fcmi_rates(fcmi_letter_rates, 8)}
            },
            flat: {
      #{format_fcmi_rates(fcmi_flat_rates, 8)}
            }
          }
          FCMI_NON_MACHINABLE_SURCHARGE = #{fcmi_nm_surcharge}

          US_LETTER_RATES = {
      #{format_simple_rates(us_letter_rates, 6)}
          }

          US_FLAT_RATES = {
      #{format_simple_rates(us_flat_rates, 6)}
          }

          US_STAMP_LETTER_RATES = {
      #{format_simple_rates(us_stamp_letter_rates, 6)}
          }

          US_STAMP_FLAT_RATES = {
      #{format_simple_rates(us_stamp_flat_rates, 6)}
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
              raise ArgumentError, "\#{weight} oz is too heavy for a \#{type}" unless rate

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
              raise ArgumentError, "\#{weight} oz is too heavy for a \#{type}" unless rate

              if non_machinable
                raise ArgumentError, "only letters can be non-machinable!" unless type == :letter
                rate += FCMI_NON_MACHINABLE_SURCHARGE
              end

              rate
            end

            def fcmi_price(processing_category, weight, country, non_machinable = false)
              type = processing_category.to_sym
              rates = FCMI_RATE_TABLE[type]

              raise ArgumentError, "idk the rates for \#{type}..." unless rates
              country = case country
              when "CA"
                          :ca
              when "MX"
                          :mx
              else
                          :other
              end

              rate = rates.find { |k, v| weight <= k }&.dig(1)
              raise "\#{weight} oz is too heavy for an FCMI \#{type}" unless rate
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
    RUBY

    File.write(Rails.root.join("app/services/usps/pricing_engine.rb"), content)
  end

  def format_fcmi_rates(rates, indent)
    lines = []
    rates.each do |weight, countries|
      lines << "#{' ' * indent}#{weight} => {"
      country_lines = countries.map { |k, v| "#{' ' * (indent + 2)}#{k}: #{format("%.2f", v)}" }
      lines << country_lines.join(",\n")
      lines << "#{' ' * indent}},"
    end
    lines.join("\n")
  end

  def format_simple_rates(rates, indent)
    rates.map { |weight, price| "#{' ' * indent}#{weight} => #{format("%.2f", price)}" }.join(",\n")
  end
end
