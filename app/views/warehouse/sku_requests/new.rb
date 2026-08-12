# frozen_string_literal: true

class Views::Warehouse::SKURequests::New < Views::Base
  def initialize(sku_request:)
    @sku_request = sku_request
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "New SKU Request")
    render Components::Warehouse::SKURequests::Form.new(sku_request: @sku_request)
  end
end
