module LSV
  class HighSeasShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :hso_table)
    self.email_column = "recipient:email"

    has_subtypes "shop_item:fulfillment_type", {
      ["minuteman"] => "LSV::HsMinutemanShipment",
      ["hq_mail"] => "LSV::HsHqMailShipment",
      ["third_party_physical"] => "LSV::HsThirdPartyPhysicalShipment",
      ["agh"] => "LSV::HsRawPendingAghShipment",
      ["agh_random_stickers"] => "LSV::HsRawPendingAghShipment",
    }

    def type_text
      "High Seas order"
    end

    def title_text
      "High Seas – #{fields["shop_item:name"] || "unknown?!"}"
    end

    def date
      self["created_at"]
    end

    def status_text
      case fields["status"]
      when "PENDING_MANUAL_REVIEW", "on_hold"
        "awaiting manual review..."
      when "AWAITING_YSWS_VERIFICATION"
        "waiting for you to get verified..."
      when "pending_nightly"
        "we'll send it out when we can!"
      when "fulfilled"
        ["sent!", "mailed!", "on its way!"].sample
      else
        super
      end
    end

    def status_icon
      case fields["status"]
      when "PENDING_MANUAL_REVIEW", "on_hold"
        '<i class="fa-solid fa-hourglass-half"></i>'
      when "AWAITING_YSWS_VERIFICATION"
        '<i class="fa-solid fa-user-clock"></i>'
      when "pending_nightly"
        '<i class="fa-solid fa-clock"></i>'
      when "fulfilled"
        '<i class="fa-solid fa-truck-fast"></i>'
      end
    end

    def tracking_number
      fields["tracking_number"]
    end

    def tracking_link
      tracking_number && "https://parcelsapp.com/en/tracking/#{tracking_number}"
    end

    def icon
      return "🎁" if fields["shop_item:name"]&.start_with? "Free"
      super
    end

    def shipped?
      fields["status"] == "fulfilled"
    end

    def internal_info_partial
      :_highseas_internal_info
    end
  end
end
