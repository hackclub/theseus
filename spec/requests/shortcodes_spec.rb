# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jumpcodes", type: :request do
  def kbar_data
    JSON.parse(response.body[%r{id="kbar-data">(.*?)</script>}m, 1])
  end

  it "does not offer admin-only destinations to a non-admin" do
    sign_in_as(create(:user, can_warehouse: true))
    get warehouse_orders_path

    expect(kbar_data["shortcuts"].map { |s| s["code"] }).not_to include("PROB")
    expect(kbar_data["prefixes"].keys).not_to include("usr")
  end

  it "still offers them to an admin" do
    sign_in_as(create_admin)
    get warehouse_orders_path

    expect(kbar_data["shortcuts"].map { |s| s["code"] }).to include("PROB")
    expect(kbar_data["prefixes"].keys).to include("usr")
  end
end
