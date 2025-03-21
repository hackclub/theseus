json.extract! warehouse_sku, :id, :sku, :description, :declared_unit_cost, :customs_description, :in_stock, :ai_enabled, :enabled, :created_at, :updated_at
json.url warehouse_sku_url(warehouse_sku, format: :json)
