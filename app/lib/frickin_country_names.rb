# this is written in blood.

module FrickinCountryNames
  class << self
    # all of these have been problems:
    SILLY_LOOKUP_TABLE = {
      "hong kong sar" => "HK",
      "россия" => "RU",
    }
    UNSTATABLE_COUNTRIES = %w[EG SG]

    def find_country(string_to_ponder)
      normalized = ActiveSupport::Inflector.transliterate(string_to_ponder.strip)
      country = ISO3166::Country.find_country_by_alpha2(normalized) ||
                ISO3166::Country.find_country_by_alpha3(normalized) ||
                ISO3166::Country.find_country_by_any_name(normalized) ||
                ISO3166::Country.find_country_by_alpha2(SILLY_LOOKUP_TABLE[string_to_ponder.strip.downcase]) ||
                ISO3166::Country.find_country_by_alpha2(SILLY_LOOKUP_TABLE[normalized.downcase])
    end

    def find_country!(string_to_ponder)
      country = find_country(string_to_ponder)
      raise ArgumentError, "couldn't parse #{string_to_ponder} as a country!" unless country
      country
    end

    def find_state(country, string_to_ponder)
      country&.find_subdivision_by_any_name(string_to_ponder)
    end

    def find_state!(country, string_to_ponder)
      state = find_state(country, string_to_ponder)
      raise ArgumentError, "couldn't parse #{string_to_ponder} as a state!" unless state
      state
    end

    def normalize_state(country, string_to_ponder)
      return string_to_ponder if UNSTATABLE_COUNTRIES.include?(country.alpha2)
      find_state(country, string_to_ponder)&.code || string_to_ponder
    end
  end
end

# lol countries can't find subdivisions by unofficial names
module ISO3166
  module CountrySubdivisionMethods
    def find_subdivision_by_any_name(subdivision_str)
      subdivisions.select do |k, v|
        subdivision_str == k || v.name == subdivision_str || v.translations&.values.include?(subdivision_str) || v.unofficial_names&.include?(subdivision_str) || stupid_compare(v.translations&.values, subdivision_str) || v.unofficial_names && stupid_compare(Array(v.unofficial_names), subdivision_str)
      end.values.first
    end

    def stupid_compare(arr, val)
      arr.map { |s| tldc(s) }.include?(val)
    end

    def tldc(s)
      ActiveSupport::Inflector.transliterate(s.strip).downcase
    end
  end
end
