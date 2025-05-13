module USPS
  class USPSError < StandardError; end

  class NotFound < USPSError; end

  class NxAddress < NotFound; end

  class NxZIP < NotFound; end
end

module FaradayMiddleware
  # USPS' oauth is silly so i'm not bothering with proper refresh tokens
  # we can just get a new client_credentials grant
  class USPSRefresh < Faraday::Middleware
    attr_reader :token
    attr_reader :client

    def call(env)
      if !@token || @token&.expired?
        @token = client.client_credentials.get_token
      end
      env[:request_headers].merge!("Authorization" => "Bearer #{@token.token}")
      @app.call(env)
    end

    def initialize(app, client = nil)
      super app
      @app = app
      @client = client
    end
  end

  class USPSErrorMiddleware < Faraday::Middleware
    def on_complete(env)
      unless env.response.success?
        unless env.response.body.respond_to?(:dig)
          uuid = Honeybadger.notify(USPS::USPSError.new(env.response.body))
          raise USPS::USPSError, "#{env.response.body} (please report EID: #{uuid})"
        end
        if env.response.body.dig(:error, :message) == "Address Not Found."
          raise USPS::NxAddress
        elsif env.response.body.dig(:error, :message) == "Invalid Zip Code."
          raise USPS::NxZIP
        else
          uuid = Honeybadger.notify(USPS::USPSError.new(env.response.body))
          raise USPS::USPSError, "#{env.response.body} (please report EID: #{uuid})"
        end
      end
    end
  end
end

Faraday::Request.register_middleware usps_refresh: FaradayMiddleware::USPSRefresh
Faraday::Response.register_middleware usps_error: FaradayMiddleware::USPSErrorMiddleware

class USPS::APIService
  ENVIRONMENT = Rails.env.production? ? :prod : :tem

  class << self
    # Returns the best standardized address for a given address
    # ---
    # Standardizes street addresses including city and street abbreviations as well as providing missing information such as ZIP Code and ZIP+4.
    #
    # Must specify a street address, a state, and either a city or a ZIP Code.
    # @param [String, nil] firm business name, helps USPS figure out suite numbers
    # @param street_address address line 1
    # @param secondary_address apt/ste/what have you
    # @param city take a wild guess
    # @param state gotta be a 2-letter abbreviation!
    # @param urbanization only in puerto rico..?
    # @param zip_code zip code, provide this if you didn't provide city!
    # @param zip_plus_4 zip+4, why would you be standardizing an address if you knew this?
    #
    # returns something in the shape of:
    #  {:firm=>"HACK CLUB",
    #   :address=>
    #    {:streetAddress=>"15 FALLS RD",
    #     :streetAddressAbbreviation=>nil,
    #     :secondaryAddress=>nil,
    #     :city=>"SHELBURNE",
    #     :cityAbbreviation=>nil,
    #     :state=>"VT",
    #     :postalCode=>nil,
    #     :province=>nil,
    #     :ZIPCode=>"05482",
    #     :ZIPPlus4=>"7480",
    #     :urbanization=>nil,
    #     :country=>nil,
    #     :countryISOCode=>nil},
    #     :additionalInfo=>{:deliveryPoint=>"15",
    #                       :carrierRoute=>"R003",
    #                       :DPVConfirmation=>"Y",
    #                       :DPVCMRA=>"N",
    #                       :business=>"Y",
    #                       :centralDeliveryPoint=>"N",
    #                       :vacant=>"N"},
    #   :corrections=>nil,
    #   :matches=>nil}
    def standardize_address(
      firm: nil,
      street_address:,
      secondary_address: nil,
      city: nil,
      state:,
      urbanization: nil,
      zip_code: nil,
      zip_plus_4: nil
    )
      conn.get("/addresses/v3/address", {
        firm: firm,
        streetAddress: street_address,
        secondaryAddress: secondary_address,
        city: city,
        state: state,
        urbanization: urbanization,
        ZIPCode: zip_code,
        ZIPPlus4: zip_plus_4,
      }.compact_blank).body
    end

    # Returns the city and state for a given ZIP Code.
    #  {:city=>"BURLINGTON", :state=>"VT", :ZIPCode=>"05401"}
    # @param [String] zip zip code
    def city_state_from_zip(zip)
      conn.get("/addresses/v3/city-state", { ZIPCode: zip }).body
    end

    # Returns the ZIP Code; and ZIP + 4; corresponding to the given address, city, and state (use USPS state abbreviations).
    # @param [String] firm Firm/business corresponding to the address.
    # @param [String] street_address The number of a building along with the name of the road or street on which it is located.
    # @param [String] secondary_address The secondary unit designator, such as apartment(APT) or suite(STE) number, defining the exact location of the address within a building.  For more information please see [Postal Explorer](https://pe.usps.com/text/pub28/28c2_003.htm).
    # @param [String] city take a wild frickin guess
    # @param [String] state capital two-character state code
    # @param [String] zip_code why would you specify this
    # @param [String] zip_plus_4 why on earth would you specify this
    #
    #  {:firm=>nil,
    #   :address=>
    #    {:streetAddress=>"15 FALLS RD",
    #     :streetAddressAbbreviation=>nil,
    #     :secondaryAddress=>nil,
    #     :secondaryAddress=>nil,
    #     :city=>"SHELBURNE",
    #     :cityAbbreviation=>nil,
    #     :state=>"VT",
    #     :postalCode=>nil,
    #     :province=>nil,
    #     :ZIPCode=>"05482",
    #     :ZIPPlus4=>"7480",
    #     :urbanization=>nil,
    #     :country=>nil,
    #     :countryISOCode=>nil}}
    def zip_code_for_address(
      firm: nil,
      street_address:,
      secondary_address: nil,
      city:,
      state:,
      zip_code: nil,
      zip_plus_4: nil
    )
      conn.get("/addresses/v3/zipcode", {
        firm: firm,
        streetAddress: street_address,
        secondaryAddress: secondary_address,
        city: city,
        state: state,
        ZIPCode: zip_code,
        ZIPPlus4: zip_plus_4,
      }.compact_blank).body
    end

    # buys a piece of domestic first-class postage!
    #
    # @param [String] payment_token USPS payment token
    # @param [String] processing_category processing category – "LETTERS" or "FLATS"
    # @param [Float] weight weight of mailpiece including envelope (ounces)
    # @param [Date] mailing_date (today->today+1 week)
    # @param [Float] length (inches)
    # @param [Float] height (inches)
    # @param [Float] thickness (inches)
    # @param non_machinable_indicators hash of {theOnesThatApply=>true}
    # @param [String] receipt_option you want a receipt with that? specify "SEPARATE_PAGE" then
    # @param [String] image_type "PDF"|"TIFF"|"JPG"|"SVG"
    # @param [String] label_type "2X1.5LABEL" for now...
    def create_fcm_indicia(
      payment_token:,
      processing_category:,
      weight:,
      mailing_date:,
      length:,
      height:,
      thickness:,
      non_machinable_indicators: {
        isPolybagged: false,
        hasClosureDevices: false,
        hasLooseItems: false,
        isRigid: false,
        isSelfMailer: false,
        isBooklet: false,
      },
      receipt_option: "NONE",
      image_type: "TIFF",
      label_type: "2X1.5LABEL"
    )
      conn.post(
        "/labels/v3/indicia",
        {
          indiciaDescription: {
            processingCategory: processing_category,
            weight: weight,
            mailingDate: mailing_date.to_s,
            length: length,
            height: height,
            thickness: thickness,
            nonMachinableIndicators: non_machinable_indicators,
          },
          imageInfo: {
            receiptOption: receipt_option,
            imageType: image_type,
            labelType: label_type,
          },
        },
        {
          "X-Payment-Authorization-Token" => payment_token,
          "Accept" => "application/vnd.usps.labels+json",
        },
      ).body
    end

    # ugh i can't document this rn
    # see https://developers.usps.com/paymentsv3#tag/Resources/operation/post-payments-payment-authorization
    # @return [String] USPS v3 payment account token
    def create_payment_token(roles:)
      conn.post("/payments/v3/payment-authorization", { roles: }).body.dig(:paymentAuthorizationToken)
    end

    def payment_account_inquiry(account_number:, account_type:, permit_zip: nil, amount: nil)
      conn.get("/payments/v3/payment-account/#{account_number}", { accountType: account_type, permitZip: permit_zip, amount: }.compact_blank).body
    end

    private

    def api_host
      host = {
        prod: "apis",
        cat: "api-cat",
        cat_no_s: "api-cat",
        tem: "apis-tem",
      }[ENVIRONMENT]
      "https://#{host}.usps.com"
    end

    def conn
      @conn ||= Faraday.new(url: api_host) do |f|
        f.request :usps_refresh, oauth2_client
        f.request :json
        f.response :usps_error
        f.response :json, parser_options: { symbolize_names: true }
      end
    end

    def oauth2_client
      @oa2_client ||= OAuth2::Client.new(
        Rails.application.credentials.usps.dig(ENVIRONMENT, :consumer_id),
        Rails.application.credentials.usps.dig(ENVIRONMENT, :consumer_secret),
        site: "#{api_host}/oauth2/v3",
        token_url: "token",
        auth_scheme: :request_body,
      )
    end
  end
end
