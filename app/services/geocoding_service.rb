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
      Rails.cache.fetch("geocode_address_#{address.id}", expires_in: 1.day) do
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
      Rails.cache.fetch("geocode_return_address_#{return_address.id}", expires_in: 1.day) do
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
      nominatim(params).first
    end

    def nominatim(params)
      Rails.logger.info "Nominatim: #{params}"
      conn.get("search.php", params.merge(format: "jsonv2")).body
    end

    private

    def conn
      @conn ||= Faraday.new(url: ENV["NOMINATIM_URL"]) do |faraday|
        faraday.request :url_encoded
        faraday.headers["User-Agent"] = "hack club / theseus (nora@hackclub.com)"
        faraday.adapter Faraday.default_adapter
        faraday.response :json, parser_options: { symbolize_names: true }
      end
    end
  end
end
