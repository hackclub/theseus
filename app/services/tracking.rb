class Tracking
  class << self
    TRACKING_URL_FORMATS = {
      asendia: "https://a1.asendiausa.com/tracking/?trackingnumber=%s",
      usps: "https://tools.usps.com/go/TrackConfirmAction_input?strOrigTrackNum=%s",
      ups: "https://www.ups.com/track?loc=en_US&tracknum=%s&requester=ST/trackdetails",
      fedex: "https://www.fedex.com/fedextrack/?trknbr=%s",
      generic: "https://parcelsapp.com/en/tracking/%s"
    }.freeze

    def tracking_url_for(format, trknum)
      return nil if !trknum || trknum.empty? # no tracking link for FCM(I) :-P

      TRACKING_URL_FORMATS[format] % trknum
    end

    def get_format_by_zenv_info(carrier:, service:)
      case carrier # figure out provider
      when "Asendia"
        :asendia
      when "UPS", "UPS by ShipStation" # whyyyy
        :ups
      when /^Stamps\.com( \(Zenventory USPS\))?$/
        case service
        when /GlobalPost .* Intl/
          :generic # these have better tracking than parcels at epgshipping.com but i can't figure out how to generate a URL to their portal
        else
          :usps # i think USPS is the only other carrier zenv uses SDC for?
        end
      when "FedEx"
        :fedex
      else
        Rails.logger.warn("missing tracking format for carrier #{carrier}")
        :generic # not a huge parcels fan but it'll catch everything else
      end
    end
  end
end
