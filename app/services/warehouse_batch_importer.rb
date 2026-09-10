# frozen_string_literal: true

# Addresses only. Orders are built from the template at process time, so the
# row checks here mirror what Warehouse::Order will refuse later: it needs an
# email, it can't go to a country the warehouse can't ship to, and customs
# wants both a phone and an email on anything leaving the US.
class WarehouseBatchImporter < BatchImporter
  private

  def restricted_countries
    restrictions = Rails.configuration.country_restrictions
    restrictions.usps_restricted + restrictions.agh_restricted
  end

  def restricted_message(country_name) = "We can't ship to #{country_name} from the warehouse"

  def validate_row(row)
    errs = super
    errs << "Email blank" if get(row, "email").blank?

    cc = country_code(row)
    if cc != "US" && !cc.in?(restricted_countries) && get(row, "phone_number").blank?
      errs << "Customs needs a phone number for #{country_name(cc)}"
    end

    errs
  end
end
