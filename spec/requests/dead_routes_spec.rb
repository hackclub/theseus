# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Routes without actions behind them", type: :request do
  def route?(verb, path)
    Rails.application.routes.recognize_path(path, method: verb)
    true
  rescue ActionController::RoutingError
    false
  end

  it "no longer routes api key edit, update or destroy" do
    expect(route?(:get, "/back_office/api_keys/1/edit")).to be(false)
    expect(route?(:patch, "/back_office/api_keys/1")).to be(false)
    expect(route?(:delete, "/back_office/api_keys/1")).to be(false)
    expect(route?(:get, "/back_office/api_keys/1")).to be(true)
  end

  it "no longer routes warehouse sku or sku request destroy" do
    expect(route?(:delete, "/back_office/warehouse/skus/1")).to be(false)
    expect(route?(:delete, "/back_office/warehouse/sku_requests/1")).to be(false)
    expect(route?(:get, "/back_office/warehouse/skus/1/edit")).to be(true)
    expect(route?(:get, "/back_office/warehouse/sku_requests/1/edit")).to be(true)
  end
end
