# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP toolboxes", type: :request do
  let(:user) { create_admin }
  let(:auth) do
    Toolchest::AuthContext.new(
      resource_owner: user,
      scopes: Toolchest.configuration.scopes.keys,
      token: nil,
    )
  end

  def dispatch(tool, args)
    Toolchest::Current.set(auth: auth) { Toolchest.router.dispatch(tool, args) }
  end

  def text_of(response) = Array(response[:content]).map { |c| c[:text] }.compact.join("\n")

  def expect_success(response)
    expect(response[:isError]).to(be_falsey, -> { "tool failed: #{text_of(response)}" })
    response
  end

  let(:address_params) do
    {
      "first_name" => "Alice",
      "last_name" => "Smith",
      "line_1" => "123 Main St",
      "city" => "Burlington",
      "state" => "VT",
      "postal_code" => "05401",
      "country" => "US"
    }
  end

  describe "letters" do
    let(:return_address) { create(:return_address) }

    it "creates a letter with a nested address" do
      response = expect_success(dispatch("letters_create", {
        "processing_category" => "letter",
        "return_address_id" => return_address.id,
        "address" => address_params
      }))

      letter = Letter.order(:id).last
      expect(letter.address.line_1).to eq("123 Main St")
      expect(text_of(response)).to include(letter.public_id)
    end

    it "updates a letter's address and flips postage when the return address leaves the US" do
      letter = create(:letter, user: user)
      international = create(:return_address, country: "CA")

      expect_success(dispatch("letters_update", {
        "letter_id" => letter.public_id,
        "return_address_id" => international.id,
        "address" => address_params.merge("line_1" => "456 Elm St")
      }))

      letter.reload
      expect(letter.address.line_1).to eq("456 Elm St")
      expect(letter.postage_type).to eq("international_origin")
      expect(letter.return_address).to eq(international)
    end
  end

  describe "warehouse orders" do
    let!(:profile) { create(:billing_profile, user: user) }
    let!(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }
    let(:template) do
      Warehouse::Template.create!(name: "Sticker pack", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
    end

    before { fake_hcb! }

    it "creates an order with nested line items and address" do
      response = expect_success(dispatch("warehouse_orders_create", {
        "user_facing_title" => "Stickers",
        "recipient_email" => "alice@example.com",
        "billing_profile_id" => profile.id.to_s,
        "line_items" => [ { "sku_id" => sku.id, "quantity" => 2 } ],
        "address" => address_params.merge("email" => "alice@example.com")
      }))

      order = Warehouse::Order.order(:id).last
      expect(order.line_items.first.quantity).to eq(2)
      expect(order.address.city).to eq("Burlington")
      expect(text_of(response)).to include(order.hc_id)
    end

    it "creates an order from a template with a nested address" do
      expect_success(dispatch("warehouse_orders_create_from_template", {
        "template_id" => template.public_id,
        "recipient_email" => "alice@example.com",
        "billing_profile_id" => profile.id.to_s,
        "address" => address_params.merge("email" => "alice@example.com")
      }))

      order = Warehouse::Order.order(:id).last
      expect(order.line_items.map(&:sku)).to eq([ sku ])
      expect(order.address.postal_code).to eq("05401")
    end

    it "updates an order's line items and address" do
      order = Warehouse::Order.from_template(
        template,
        user: user, recipient_email: "alice@example.com",
        address: create(:address, country: "US"), billing_profile: profile,
      ).tap(&:save!)

      expect_success(dispatch("warehouse_orders_update", {
        "order_id" => order.hc_id,
        "line_items" => [ { "id" => order.line_items.first.id, "sku_id" => sku.id, "quantity" => 5 } ],
        "address" => address_params.merge("city" => "Montpelier")
      }))

      order.reload
      expect(order.line_items.first.quantity).to eq(5)
      expect(order.address.city).to eq("Montpelier")
    end
  end

  describe "id prefixes in tool descriptions" do
    it "uses the real ! separator" do
      descriptions = Toolchest.router.tools_list.flat_map { |t| [ t[:description], t.dig(:inputSchema, :properties).to_s ] }.join(" ")
      expect(descriptions).not_to match(/\b(ltr|pkg|wot)_\.\.\./)
    end
  end
end
