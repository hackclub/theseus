module USPS
  class PricingEngine
    CACHE_TTL = 1.day

    class << self
      def metered_price(processing_category, weight, non_machinable = false)
        extract_domestic_rate("COMMERCIAL", processing_category, weight, non_machinable)
      end

      def domestic_stamp_price(processing_category, weight, non_machinable = false)
        extract_domestic_rate("RETAIL", processing_category, weight, non_machinable)
      end

      def fcmi_price(processing_category, weight, country, non_machinable = false)
        key = cache_key("fcmi", processing_category, weight, country: country, non_machinable: non_machinable)
        Rails.cache.fetch(key, expires_in: CACHE_TTL) do
          response = USPS::APIService.international_letter_price(
            processing_category: processing_category.to_s.pluralize.upcase,
            weight: weight.to_f,
            destination_country_code: country,
            non_machinable_indicators: non_machinable ? { isRigid: true } : {},
          )
          extract_price(response)
        end
      end

      def stamp_price(processing_category, weight, country, non_machinable = false)
        if country == "US"
          domestic_stamp_price(processing_category, weight, non_machinable)
        else
          fcmi_price(processing_category, weight, country, non_machinable)
        end
      end

      private

      def extract_domestic_rate(price_type, processing_category, weight, non_machinable)
        response = cached_domestic_response(processing_category, weight, non_machinable)
        rate = response[:rates]&.find { |r| r[:priceType] == price_type } || response[:rates]&.first
        raise "no #{price_type} rate from USPS for #{processing_category} #{weight}oz" unless rate
        rate[:price].to_f + (rate[:fees] || []).sum { |f| f[:price].to_f }
      end

      def cached_domestic_response(processing_category, weight, non_machinable)
        key = cache_key("fcm", processing_category, weight, non_machinable: non_machinable)
        Rails.cache.fetch(key, expires_in: CACHE_TTL) do
          USPS::APIService.letter_price(
            processing_category: processing_category.to_s.pluralize.upcase,
            weight: weight.to_f,
            non_machinable_indicators: non_machinable ? { isRigid: true } : {},
          )
        end
      end

      def extract_price(response)
        rate = response[:rates]&.first
        raise "no rate returned from USPS" unless rate
        rate[:price].to_f + (rate[:fees] || []).sum { |f| f[:price].to_f }
      end

      def cache_key(type, processing_category, weight, country: nil, non_machinable: false)
        parts = ["usps_rate", type, processing_category, "#{weight}oz"]
        parts << country.to_s.downcase if country
        parts << "nm" if non_machinable
        parts.join("_")
      end
    end
  end
end
