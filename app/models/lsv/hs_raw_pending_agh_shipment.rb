module LSV
  class HsRawPendingAghShipment < HighSeasShipment
    def type_text = "Pending warehouse shipment"

    def status_text
      case status
      when "pending_nightly"
        "will be sent to the warehouse with the next batch!"
      else
        super
      end
    end

    def status_icon
      return '<i class="fa-solid fa-boxes-stacked"></i>' if status == "pending_nightly"
      super
    end
  end
end
