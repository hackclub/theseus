json.tag @tag

json.letters do
  json.count @letter_count
  json.postage_cost @letter_postage_cost
end

json.warehouse_orders do
  json.count @warehouse_order_count
  json.postage_cost @warehouse_order_postage_cost
  json.labor_cost @warehouse_order_labor_cost
  json.contents_cost @warehouse_order_contents_cost
  json.total_cost @warehouse_order_total_cost
end
