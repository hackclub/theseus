module LSV
  class HsThirdPartyPhysicalShipment < HighSeasShipment
    def type_text = "High Seas 3rd-party physical"

    def status_text
      case status
      when "pending_nightly"
        "will be ordered soon..."
      when "fulfilled"
        "ordered!"
      else
        super
      end
    end
  end
end
