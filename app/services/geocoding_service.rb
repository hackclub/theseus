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
          city: address.city,
          state: address.state,
          postalcode: address.postal_code,
          country: address.country,
        }
        params[:street] = address.line_1 if exact

        first_hit(params) || FIFTEEN_FALLS
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
      google_geocode(params)
    end

    def google_geocode(params)
      Rails.logger.info "Google Geocoding: #{params}"

      address_components = []
      address_components << params[:street] if params[:street]
      address_components << params[:city] if params[:city]
      address_components << params[:state] if params[:state]
      address_components << params[:postalcode] if params[:postalcode]
      address_components << params[:country] if params[:country]

      address = address_components.join(", ")

      response = conn.get("maps/api/geocode/json", {
        address: address,
        key: ENV["GOOGLE_MAPS_API_KEY"]
      })

      results = response.body["results"]
      return nil if results.empty?

      result = results.first
      location = result["geometry"]["location"]

      {
        lat: location["lat"].to_s,
        lon: location["lng"].to_s,
        display_name: result["formatted_address"],
        place_id: result["place_id"]
      }
    end

    private

    def conn
      @conn ||= Faraday.new(url: "https://maps.googleapis.com/") do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
        faraday.response :json
      end
    end
  end
end
