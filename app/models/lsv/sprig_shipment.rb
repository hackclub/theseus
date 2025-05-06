module LSV
  class SprigShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :sprig_table)
    self.email_column = "Email"

    def title_text
      "Sprig!"
    end

    def type_text
      "Sprig shipment"
    end

    def date
      fields["Created At"]
    end

    def status_text
      if shipped?
        "shipped via #{fields["Carrier"] || "...we don't know"}!"
      else
        "pending..."
      end
    end

    def status_icon
      if shipped?
        '<i class="fa-solid fa-truck"></i>'
      else
        '<i class="fa-solid fa-clock"></i>'
      end
    end

    def tracking_link
      fields["Tracking"] && "#{(fields["Tracking Base Link"] || "https://parcelsapp.com/en/tracking/")}#{fields["Tracking"]}"
    end

    def tracking_number
      fields["Tracking"]
    end

    def icon
      "🌱"
    end

    def shipped?
      fields["Sprig Status"] == "Shipped"
    end

    def description
      "a #{fields["Color"]&.downcase.concat " "}Sprig!"
    end
  end
end
