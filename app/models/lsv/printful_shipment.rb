module LSV
  class PrintfulShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :pf_table)
    field :email, "%order:recipient:email"
    field :status, "status"
    field :service, "service"
    field :ship_date, "ship_date"
    field :tracking_number, "tracking_number"
    field :tracking_url_field, "tracking_url"
    field :order_items_json, "%order:items"
    field :items_json, "items"
    field :order_created, "%order:created"
    field :created_field, "created"
    field :subtype_field, "subtype"
    field :order_pretty_id, "%order:pretty_id"
    field :order_dashboard_url, "%order:dashboard_url"
    field :packing_slip_url, "packing_slip_url"

    def to_partial_path = "lsv/type/printful_shipment"

    has_subtypes "subtype", {
      "mystic_tavern" => "LSV::MysticTavernShipment"
    }

    def date = created_field || Date.parse(order_created).iso8601

    def title_text = "something custom!"

    def type_text = "Printful shipment"

    def icon = "🧢"

    def status_text
      case status
      when "pending"
        "pending..."
      when "onhold"
        "on hold!?"
      when "shipped"
        "shipped via #{service} on #{ship_date}!"
      when "started"
        "in production!"
      end
    end

    def shipped? = status == "shipped"

    def status_icon
      if shipped?
        '<i class="fa-solid fa-truck"></i>'
      else
        '<i class="fa-solid fa-clock"></i>'
      end
    end

    def description
      order_items = try_to_parse(order_items_json)&.index_by { |item| item["id"] }
      shipment_items = try_to_parse(items_json)

      shipment_items.map do |si|
        name = order_items&.dig(si["item_id"], "name") || "???"
        qty = si["quantity"]
        qty != 1 ? "#{qty}x #{name}" : name
      end
    end

    def tracking_link = (tracking_url_field if tracking_number)

    def internal_info_partial = :_printful_internal_info

    private

    def try_to_parse(json)
      JSON.parse(json) if json
    rescue JSON::ParserError
      nil
    end
  end

  class MysticTavernShipment < PrintfulShipment
    def title_text = "Mystic Tavern shirts!"

    def type_text = "arrrrrrrrrrrrr"

    def icon = "��"
  end
end
