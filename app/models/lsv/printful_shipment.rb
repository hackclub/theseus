module LSV
  class PrintfulShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :pf_table)
    self.email_column = "%order:recipient:email"

    def to_partial_path
      "lsv/type/printful_shipment"
    end

    has_subtypes "subtype", {
      "mystic_tavern" => "LSV::MysticTavernShipment",
    }

    def date
      fields["created"] || Date.parse(fields["%order:created"]).iso8601
    end

    def title_text
      "something custom!"
    end

    def type_text
      "Printful shipment"
    end

    def icon
      "🧢"
    end

    def status_text
      case fields["status"]
      when "pending"
        "pending..."
      when "onhold"
        "on hold!?"
      when "shipped"
        "shipped via #{fields["service"]} on #{fields["ship_date"]}!"
      when "started"
        "in production!"
      end
    end

    def shipped?
      fields["status"] == "shipped"
    end

    def status_icon
      if shipped?
        '<i class="fa-solid fa-truck"></i>'
      else
        '<i class="fa-solid fa-clock"></i>'
      end
    end

    def description
      order_items = try_to_parse(fields["%order:items"])&.index_by { |item| item["id"] }
      shipment_items = try_to_parse(fields["items"])

      shipment_items.map do |si|
        name = order_items&.dig(si["item_id"], "name") || "???"
        qty = si["quantity"]
        qty != 1 ? "#{qty}x #{name}" : name
      end
    end

    def tracking_number
      fields["tracking_number"]
    end

    def tracking_link
      fields["tracking_url"] if tracking_number
    end

    def internal_info_partial
      :_printful_internal_info
    end

    private

    def try_to_parse(json)
      JSON.parse(json) if json
    rescue JSON::ParserError
      nil
    end
  end

  class MysticTavernShipment < PrintfulShipment
    def title_text
      "Mystic Tavern shirts!"
    end

    def type_text
      "arrrrrrrrrrrrr"
    end

    def icon
      "��"
    end
  end
end
