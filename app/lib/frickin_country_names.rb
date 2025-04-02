# this is written in blood.

module FrickinCountryNames
  class << self
    # all of these have been problems:
    SILLY_LOOKUP_TABLE = {
      "hong kong sar" => "HK"
    }

    def find_country(string_to_ponder)
      normalized = ActiveSupport::Inflector.transliterate(string_to_ponder.strip)
      country = ISO3166::Country.find_country_by_alpha2(normalized) ||
        ISO3166::Country.find_country_by_alpha3(normalized) ||
        ISO3166::Country.find_country_by_any_name(normalized) ||
        ISO3166::Country.find_country_by_alpha2(SILLY_LOOKUP_TABLE[normalized.downcase])
    end

    def find_country!(string_to_ponder)
      country = find_country(string_to_ponder)
      raise ArgumentError, "couldn't parse #{string_to_ponder} as a country!" unless country
      country
    end
  end
end