module LSV
  class OneOffShipment < Base
    self.base_key = Rails.application.credentials.dig(:lsv, :sv_base)
    self.table_name = Rails.application.credentials.dig(:lsv, :oo_table)
    self.email_column = "email"

    SUPPORTED_FIELDS = %i[tracking_number status_text icon hide_contents? status_icon shipped? description type_text title_text]

    def tracking_link
      fields["tracking_link"] || (tracking_number && "https://parcelsapp.com/en/tracking/#{tracking_number}") || nil
    end

    def date
      fields["date"] || "2027-01-31"
    end

    def icon
      fields["icon"] || super
    end

    SUPPORTED_FIELDS.each do |field|
      define_method field do
        fields[field.to_s]
      end
    end
  end
end
