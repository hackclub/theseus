module LSV
  class HighSeasShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :hso_table)
    self.slug = :hs

    field :email, "recipient:email"
    field :status, "status"
    field :shop_item_name, "shop_item:name"
    field :tracking_number, "tracking_number"
    field :airtable_created_at, "created_at"

    has_subtypes "shop_item:fulfillment_type", {
      [ "minuteman" ] => "LSV::HsMinutemanShipment",
      [ "hq_mail" ] => "LSV::HsHqMailShipment",
      [ "third_party_physical" ] => "LSV::HsThirdPartyPhysicalShipment",
      [ "agh" ] => "LSV::HsRawPendingAghShipment",
      [ "agh_random_stickers" ] => "LSV::HsRawPendingAghShipment"
    }

    def type_text = "High Seas order"

    def title_text = "High Seas – #{shop_item_name || "unknown?!"}"

    def date = airtable_created_at

    def status_text
      case status
      when "PENDING_MANUAL_REVIEW", "on_hold"
        "awaiting manual review..."
      when "AWAITING_YSWS_VERIFICATION"
        "waiting for you to get verified..."
      when "pending_nightly"
        "we'll send it out when we can!"
      when "fulfilled"
        [ "sent!", "mailed!", "on its way!" ].sample
      else
        super
      end
    end

    def status_icon
      case status
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

    def tracking_link = tracking_number && "https://parcelsapp.com/en/tracking/#{tracking_number}"

    def icon
      return "🎁" if shop_item_name&.start_with? "Free"
      super
    end

    def shipped? = status == "fulfilled"

    def internal_info_partial = :_highseas_internal_info
  end
end
