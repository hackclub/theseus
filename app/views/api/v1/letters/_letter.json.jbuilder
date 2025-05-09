json.id letter.public_id
json.sender letter.user.public_id
json.status letter.aasm_state
json.tags letter.tags
json.return_address do
  json.name letter.return_address_name_line
  json.partial! letter.return_address
end
json.address { json.partial! letter.address }
expand :label do
  json.url rails_blob_url(letter.label) if letter.label.attached?
end
json.rubber_stamps letter.rubber_stamps
json.metadata letter.metadata || {}
