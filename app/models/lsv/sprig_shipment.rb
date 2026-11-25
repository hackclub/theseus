module LSV
  class SprigShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :sprig_table)
    field :email, "Email"
    field :sprig_status, "Sprig Status"
    field :sprig_created_at, "Created At"
    field :carrier, "Carrier"
    field :tracking, "Tracking"
    field :tracking_base_link, "Tracking Base Link"
    field :color, "Color"

    def title_text = "Sprig!"

    def type_text = "Sprig shipment"

    def date = sprig_created_at

    def status_text
      if shipped?
        "shipped via #{carrier || "...we don't know"}!"
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

    def tracking_link = tracking && "#{tracking_base_link || "https://parcelsapp.com/en/tracking/"}#{tracking}"
    def tracking_number = tracking

    def icon = "🌱"

    def shipped? = sprig_status == "Shipped"

    def description = "a #{color&.downcase.concat " "}Sprig!"
  end
end
