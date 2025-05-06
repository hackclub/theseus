module LSV
  class HsMinutemanShipment < HighSeasShipment
    def status_text
      case fields["status"]
      when "pending_nightly"
        "will go out in next week's batch..."
      when "fulfilled"
        "has gone out/will go out over the next week!"
      else
        super
      end
    end

    def status_icon
      case fields["status"]
      when "pending_nightly"
        '<i class="fa-solid fa-envelopes-bulk"></i>'
      when "fulfilled"
        '<i class="fa-solid fa-envelope-circle-check"></i>'
      else
        super
      end
    end

    def icon
      "��"
    end
  end
end
