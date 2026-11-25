module LSV
  class OneOffShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :oo_table)
    self.slug = :oo
    field :email, "email"
    field :tracking_number, "tracking_number"
    field :status_text, "status_text"
    field :status_icon, "status_icon"
    field :description, "description"
    field :type_text, "type_text"
    field :title_text, "title_text"

    def tracking_link
      self["tracking_link"] || (tracking_number && "https://parcelsapp.com/en/tracking/#{tracking_number}") || nil
    end

    def date = self["date"] || "2027-01-31"

    def icon = self["icon"] || super

    def hide_contents? = self["hide_contents?"]

    def shipped? = self["shipped?"]
  end
end
