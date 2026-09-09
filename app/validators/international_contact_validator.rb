# Customs wants a way to reach the recipient of an international parcel. The Zenventory
# payload builders end in .compact_blank, so a missing phone or email isn't an error --
# it gets quietly dropped and the box turns up at the border with no contact info.
#
#   validates :address, international_contact: true
#   validates :address, international_contact: { email: :recipient_email }
#
# :email names the attribute on the record that holds the recipient's email, for models
# that keep it off the address. Defaults to the address's own :email.
class InternationalContactValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, address)
    # a missing or countryless address is somebody else's validation to complain about
    return if address.blank? || address.country.blank? || address.us?

    missing = []
    missing << "a phone number" if address.phone_number.blank?
    missing << "an email address" if email_for(record, address).blank?
    return if missing.empty?

    record.errors.add(
      attribute,
      :missing_international_contact,
      message: "needs #{missing.to_sentence} — customs requires contact info for shipments to #{country_name(address)}."
    )
  end

  private

  def email_for(record, address)
    options[:email] ? record.public_send(options[:email]) : address.email
  end

  def country_name(address) = ISO3166::Country[address.country]&.common_name || address.country
end
