module LSV
  class BobaDropsShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :boba_table)
    self.slug = :boba
    field :email, "Email"
    field :physical_status, "Physical Status"
    field :approved_at, "[Shipment Viewer] Approved/pending at"
    field :intl_tracking_link, "[INTL] Tracking Link"
    field :intl_tracking_id, "[INTL] Tracking ID"

    def title_text = "Boba Drops!"

    def type_text = "Boba Drops Shipment"

    def date = approved_at || "error!"

    def status_text
      case physical_status
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
      case physical_status
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

    def tracking_link = intl_tracking_link
    def tracking_number = intl_tracking_id

    def icon = "🧋"

    def shipped? = physical_status == "Shipped"

    def description = "shipment from boba drops <3"
  end
end
