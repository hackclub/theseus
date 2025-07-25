module GeocodingService
  FIFTEEN_FALLS = { place_id: 339396112,
                    licence: "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
                    osm_type: "node",
                    osm_id: 12202788601,
                    lat: "44.3805465",
                    lon: "-73.2270890",
                    category: "office",
                    type: "ngo",
                    place_rank: 30,
                    importance: 5.165255207136671e-05,
                    addresstype: "office",
                    name: "Hack Club HQ",
                    display_name: "Hack Club HQ, 15, Falls Road, Shelburne Village Historic District, Shelburne, Chittenden County, Vermont, 05482, United States",
                    boundingbox: ["44.3804965", "44.3805965", "-73.2271390", "-73.2270390"] }

  class << self
    def geocode_address_model(address, exact: false)
      Rails.cache.fetch("geocode_address_#{address.id}", expires_in: 5.months) do
        params = {
          street: address.line_1,
          city: address.city,
          state: address.state,
          postalcode: address.postal_code,
          country: address.country,
        }

        result = first_hit(params) || FIFTEEN_FALLS
        result[:lat] = result[:lat].to_f
        result[:lon] = result[:lon].to_f
        result = fuzz_coordinates(result[:lat], result[:lon]) unless exact
        result
      end
    end

    def geocode_return_address(return_address, exact: false)
      Rails.cache.fetch("geocode_return_address_#{return_address.id}", expires_in: 5.months) do
        params = {
          city: return_address.city,
          state: return_address.state,
          postalcode: return_address.postal_code,
          country: return_address.country,
        }
        params[:street] = return_address.line_1 if exact

        first_hit(params) || FIFTEEN_FALLS
      end
    end

    def first_hit(params)
      hackclub_geocode(params)
    end

    def fuzz_coordinates(lat, lon)
      # Add random offset within 5 mile radius, with minimum of 3 miles for privacy
      # 1 degree latitude ≈ 69 miles, so 15 miles ≈ 0.2175 degrees
      # 1 degree longitude varies by latitude, but at ~45°N ≈ 49 miles, so 15 miles ≈ 0.306 degrees
      max_lat_offset = 0.2175
      max_lon_offset = 0.306 * Math.cos(lat * Math::PI / 180)

      # Generate random angle and distance within the annular ring (3-5 miles)
      angle = rand * 2 * Math::PI

      # For uniform distribution in annular ring, we need to account for quadratic area growth
      # Area of annular ring = π(r_max² - r_min²)
      # For uniform distribution: rand = (r² - r_min²) / (r_max² - r_min²)
      # Solving for r: r = sqrt(r_min² + rand * (r_max² - r_min²))
      min_distance_factor = 0.6  # 3 miles / 5 miles
      max_distance_factor = 1.0  # 5 miles / 5 miles

      # Calculate distance factor using proper area-based distribution
      min_squared = min_distance_factor ** 2
      max_squared = max_distance_factor ** 2
      distance_factor = Math.sqrt(min_squared + rand * (max_squared - min_squared))

      lat_offset = distance_factor * max_lat_offset * Math.sin(angle)
      lon_offset = distance_factor * max_lon_offset * Math.cos(angle)

      fuzzed_lat = lat + lat_offset
      fuzzed_lon = lon + lon_offset

      # Reduce precision to ~100m resolution (3 decimal places)
      {
        lat: fuzzed_lat.round(3),
        lon: fuzzed_lon.round(3),
      }
    end

    def hackclub_geocode(params)
      return nil if params.nil?

      Rails.logger.info "Hack Club Geocoding: #{params}"

      address_components = []
      address_components << params[:street] if params[:street]
      address_components << params[:city] if params[:city]
      address_components << params[:state] if params[:state]
      address_components << params[:postalcode] if params[:postalcode]
      address_components << params[:country] if params[:country]

      address = address_components.join(", ")

      response = conn.get("v1/geocode", {
        address: address,
        key: ENV["HACKCLUB_GEOCODER_API_KEY"],
      })

      # Handle error responses
      if response.body.key?("error")
        Rails.logger.error "Hack Club Geocoder error: #{response.body["error"]}"
        Honeybadger.notify("Geocoding error: #{response.body["error"]}")
        return nil
      end

      # Parse successful response
      result = response.body

      {
        lat: result["lat"].to_s,
        lon: result["lng"].to_s, # hc api returns "lng", we convert to "lon" for consistency with OSM
        display_name: result["formatted_address"],
        place_id: result.dig("raw_backend_response", "results", 0, "place_id") || "dunno",
      }
    rescue => e
      Rails.logger.error "Hack Club Geocoder request failed: #{e.message}"
      Honeybadger.notify(e)
      nil
    end

    private

    def conn
      @conn ||= Faraday.new(url: "https://geocoder.hackclub.com/") do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
        faraday.response :json
      end
    end
  end
end
