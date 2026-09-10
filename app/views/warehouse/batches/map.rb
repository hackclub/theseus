# frozen_string_literal: true

class Views::Warehouse::Batches::Map < Views::Batches::Map
  ADDRESS_FIELDS = Views::Batches::Map::ADDRESS_FIELDS.map do |value, label|
    case value
    when "email" then [ value, "Email *" ]
    when "phone_number" then [ value, "Phone (required outside the US)" ]
    else [ value, label ]
    end
  end.freeze

  private

  def batch_path = warehouse_batch_path(@batch)
  def set_mapping_path = set_mapping_warehouse_batch_path(@batch)
  def submit_label = "✓ Map & Import Addresses"
  def address_fields = ADDRESS_FIELDS

  def hint
    p(class: "text-muted") do
      plain "Every row becomes a warehouse order, so each one needs an email. Customs also wants a phone number for anything shipping outside the US."
    end
  end
end
