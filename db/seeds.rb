# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
ReturnAddress.find_or_create_by!(id: 1) do |address|
  address.name = "Hack Club"
  address.line_1 = "15 Falls Rd."
  address.city = "Shelburne"
  address.state = "VT"
  address.postal_code = "05482"
  address.country = "US"
  address.shared = true
end

USPS::MailerId.find_or_create_by(id: 1) do |mid|
  mid.name = "Hack Club (Shelburne)"
  mid.crid = "40039652"
  mid.mid = "903258919"
end

# Warehouse::PurposeCode.find_or_create_by!(
#   code: Rails.env.production? ? 'HQ' : 'HQ-dev',
#   description: 'general HQ mailing'
# )
