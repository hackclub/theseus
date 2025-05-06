module LSV
  class BobaDropsShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :boba_table)
    self.email_column = "Email"

    def title_text
      "Boba Drops!"
    end

    def type_text
      "Boba Drops Shipment"
    end

    def date
      self["[Shipment Viewer] Approved/pending at"] || "error!"
    end

    def status_text
      case fields["Physical Status"]
      when "Pending"
        "pending!"
      when "Packed"
        "labelled!"
      when "Shipped"
        "shipped!"
      else
        "please contact leow@hackclub.com, something went wrong!"
      end
    end

    def status_icon
      case fields["Physical Status"]
      when "Pending"
        '<i class="fa-solid fa-clock"></i>'
      when "Packed"
        '<i class="fa-solid fa-dolly"></i>'
      when "Shipped"
        '<i class="fa-solid fa-truck-fast"></i>'
      else
        '<i class="fa-solid fa-circle-exclamation"></i>'
      end
    end

    def tracking_link
      fields["[INTL] Tracking Link"]
    end

    def tracking_number
      fields["[INTL] Tracking ID"]
    end

    def icon
      "🧋"
    end

    def shipped?
      fields["Physical Status"] == "Shipped"
    end

    def description
      "shipment from boba drops <3"
    end
  end
end
