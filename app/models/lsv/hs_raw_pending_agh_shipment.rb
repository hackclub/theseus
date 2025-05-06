module LSV
  class HsRawPendingAghShipment < HighSeasShipment
    def type_text
      "Pending warehouse shipment"
    end

    def status_text
      case fields["status"]
      when "pending_nightly"
        "will be sent to the warehouse with the next batch!"
      else
        super
      end
    end

    def status_icon
      return '<i class="fa-solid fa-boxes-stacked"></i>' if fields["status"] == "pending_nightly"
      super
    end
  end
end
