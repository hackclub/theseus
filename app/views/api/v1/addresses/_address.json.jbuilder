json.first_name address.first_name
json.last_name address.last_name
pii do
  json.line_1 address.line_1
  json.line_2 address.line_2 if address.line_2.present?
  json.city address.city
  json.state address.state
  json.postal_code address.postal_code
  json.country address.country
  json.phone_number address.phone_number if address.phone_number.present?
end