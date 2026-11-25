module LSV
  class MarketingShipmentRequest < Base
    def to_partial_path = "lsv/type/msr"

    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :msr_table)
    self.slug = :msr

    field :email, "Email"
    field :airtable_automation_id, "Airtable ID (Automation)"
    field :tracking_number, "Warehouse–Tracking Number"
    field :state, "state"
    field :user_facing_title, "user_facing_title"
    field :request_type, "Request Type"
    field :date_requested, "Date Requested"
    field :tracking_url, "Warehouse–Tracking URL"
    field :surprise, "surprise"
    field :country, "Country"
    field :warehouse_service, "Warehouse–Service"
    field :user_facing_description, "user_facing_description"
    field :items_shipped_json, "Warehouse–Items Shipped JSON"
    field :postage_cost, "Warehouse–Postage Cost"

    def type_text = "Warehouse"

    def title_text
      user_facing_title || request_type&.join(", ") || "Who knows?"
    end

    def date = date_requested

    def status_text
      case state
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
      case state
      when "dispatched"
        '<i class="fa-solid fa-dolly"></i>'
      when "mailed"
        '<i class="fa-solid fa-truck-fast"></i>'
      else
        '<i class="fa-solid fa-clock"></i>'
      end
    end

    def tracking_link
      tracking_url
    end

    def tracking_number
      self["Warehouse–Tracking Number"] unless self["Warehouse–Tracking Number"] == "Not Provided"
    end

    def hide_contents? = surprise

    def country
      FrickinCountryNames.find_country(self["Country"])&.alpha2 || "US"
    end

    def icon
      return "🎁" if hide_contents? || title_text.start_with?("High Seas – Free")
      return "💵" if request_type&.include?("Boba Drop grant")
      return "✉️" if warehouse_service&.include?("First Class")
      "📦"
    end

    def shipped? = state == "mailed"

    def description
      return "it's a surprise!" if hide_contents?
      begin
        user_facing_description ||
          items_shipped_json && JSON.parse(items_shipped_json).select { |item| (item["quantity"]&.to_i || 0) > 0 }.map do |item|
            "#{item["quantity"]}x #{item["name"]}"
          end
      rescue JSON::ParserError
        "error parsing JSON for #{source_id}!"
      end
    end
  end
end
