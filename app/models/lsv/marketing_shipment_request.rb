module LSV
  class MarketingShipmentRequest < Base
    def to_partial_path
      "lsv/type/msr"
    end

    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :msr_table)
    self.email_column = "Email"

    def type_text
      "Warehouse"
    end

    def title_text
      fields["user_facing_title"] || fields["Request Type"]&.join(", ") || "Who knows?"
    end

    def date
      self["Date Requested"]
    end

    def status_text
      case fields["state"]
      when "dispatched"
        "sent to warehouse..."
      when "mailed"
        "shipped!"
      when "ON_HOLD"
        "on hold... contact us for more info!"
      when "canceled"
        "canceled?"
      else
        "this shouldn't happen."
      end
    end

    def status_icon
      case fields["state"]
      when "dispatched"
        '<i class="fa-solid fa-dolly"></i>'
      when "mailed"
        '<i class="fa-solid fa-truck-fast"></i>'
      else
        '<i class="fa-solid fa-clock"></i>'
      end
    end

    def tracking_link
      fields["Warehouse–Tracking URL"]
    end

    def tracking_number
      fields["Warehouse–Tracking Number"] unless fields["Warehouse–Tracking Number"] == "Not Provided"
    end

    def hide_contents?
      fields["surprise"]
    end

    def country
      FrickinCountryNames.find_country(fields["Country"])&.alpha2 || "US"
    end

    def icon
      return "🎁" if hide_contents? || title_text.start_with?("High Seas – Free")
      return "💵" if fields["Request Type"]&.include?("Boba Drop grant")
      return "✉️" if fields["Warehouse–Service"]&.include?("First Class")
      "📦"
    end

    def shipped?
      fields["state"] == "mailed"
    end

    def description
      return "it's a surprise!" if hide_contents?
      begin
        fields["user_facing_description"] ||
          fields["Warehouse–Items Shipped JSON"] && JSON.parse(fields["Warehouse–Items Shipped JSON"]).select { |item| (item["quantity"]&.to_i || 0) > 0 }.map do |item|
            "#{item["quantity"]}x #{item["name"]}"
          end
      rescue JSON::ParserError
        "error parsing JSON for #{source_id}!"
      end
    end
  end
end
