module LSV
  class HsHqMailShipment < HighSeasShipment
    def type_text = "High Seas shipment (from HQ)"

    def status_text
      case status
      when "pending_nightly"
        [ "we'll ship it when we can!", "will be sent when dinobox gets around to it" ].sample
      else
        super
      end
    end

    def status_icon
      case status
      when "fulfilled"
        '<i class="fa-solid fa-truck"></i>'
      else
        super
      end
    end
  end
end
