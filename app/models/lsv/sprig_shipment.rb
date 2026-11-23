module LSV
  class SprigShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :sprig_table)
    field :email, "Email"

    def title_text = "Sprig!"

    def type_text = "Sprig shipment"

    def date = fields["Created At"]

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

    def tracking_link = fields["Tracking"] && "#{(fields["Tracking Base Link"] || "https://parcelsapp.com/en/tracking/")}#{fields["Tracking"]}"
    def tracking_number = fields["Tracking"]

    def icon = "🌱"

    def shipped? = fields["Sprig Status"] == "Shipped"

    def description = "a #{fields["Color"]&.downcase.concat " "}Sprig!"
  end
end
