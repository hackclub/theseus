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

    it "does not show another user's letter to a non-admin" do
      someone_else = create(:letter)
      non_admin = create(:user)
      restricted = Toolchest::AuthContext.new(resource_owner: non_admin, scopes: Toolchest.configuration.scopes.keys, token: nil)

      response = Toolchest::Current.set(auth: restricted) { Toolchest.router.dispatch("letters_show", { "letter_id" => someone_else.public_id }) }

      expect(response[:isError]).to be_truthy
      expect(text_of(response)).not_to include(someone_else.address.line_1)
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


  describe "theseus whoami" do
    it "returns the current user's identity and permissions" do
      response = expect_success(dispatch("theseus_whoami", {}))
      data = JSON.parse(text_of(response))
      
      expect(data["id"]).to eq(user.id)
      expect(data["username"]).to eq(user.username)
      expect(data["email"]).to eq(user.email)
      expect(data["permissions"]["admin"]).to be_truthy
      expect(data["counts"]["letters"]).to be_a(Integer)
    end
  end

  describe "theseus lookup" do
    it "resolves a letter by public ID" do
      letter = create(:letter, user: user)
      response = expect_success(dispatch("theseus_lookup", { "id" => letter.public_id }))
      data = JSON.parse(text_of(response))
      
      expect(data["type"]).to eq("Letter")
      expect(data["id"]).to eq(letter.public_id)
    end

    it "resolves a warehouse order by package ID" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku)
      order = Warehouse::Order.from_template(
        Warehouse::Template.create!(name: "Test", user: user, public: true)
          .tap { |t| t.line_items.create!(sku: sku, quantity: 1) },
        user: user, recipient_email: "test@example.com",
        address: create(:address), billing_profile: profile
      ).tap(&:save!)
      
      response = expect_success(dispatch("theseus_lookup", { "id" => order.public_id }))
      data = JSON.parse(text_of(response))
      
      expect(data["type"]).to eq("Warehouse::Order")
      expect(data["id"]).to eq(order.hc_id)
    end

    it "resolves a warehouse order by tracking number" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku)
      tracking = "94346501061000000000"
      order = Warehouse::Order.from_template(
        Warehouse::Template.create!(name: "Test", user: user, public: true)
          .tap { |t| t.line_items.create!(sku: sku, quantity: 1) },
        user: user, recipient_email: "test@example.com",
        address: create(:address), billing_profile: profile
      ).tap { |o| o.update!(tracking_number: tracking); o.save! }
      
      response = expect_success(dispatch("theseus_lookup", { "id" => tracking }))
      data = JSON.parse(text_of(response))
      
      expect(data["tracking"]).to eq(tracking)
    end

    it "returns error when ID is not found" do
      response = dispatch("theseus_lookup", { "id" => "totally_bogus_id_xyz" })
      
      expect(response[:isError]).to be_truthy
      expect(text_of(response)).to include("Nothing found")
    end
  end

  describe "letters search" do
    before { fake_hcb! }
    it "returns letters scoped to the current user (admin sees all, so use non-admin)" do
      # Create a non-admin user for testing scoping
      non_admin_user = create(:user)
      non_admin_auth = Toolchest::AuthContext.new(
        resource_owner: non_admin_user,
        scopes: Toolchest.configuration.scopes.keys,
        token: nil
      )
      
      my_letter = create(:letter, user: non_admin_user)
      other_letter = create(:letter)  # Created by admin
      
      response = Toolchest::Current.set(auth: non_admin_auth) do
        Toolchest.router.dispatch("letters_search", {})
      end
      response = expect_success(response)
      data = JSON.parse(text_of(response))
      
      letter_ids = data["letters"].map { |l| l["id"] }
      expect(letter_ids).to include(my_letter.public_id)
      expect(letter_ids).not_to include(other_letter.public_id)
    end

    it "filters by status" do
      pending_letter = create(:letter, user: user, aasm_state: "pending")
      printed_letter = create(:letter, user: user, aasm_state: "printed")
      
      response = expect_success(dispatch("letters_search", { "status" => "pending" }))
      data = JSON.parse(text_of(response))
      
      letter_ids = data["letters"].map { |l| l["id"] }
      expect(letter_ids).to include(pending_letter.public_id)
      expect(letter_ids).not_to include(printed_letter.public_id)
    end
  end

  describe "warehouse_orders search" do
    before { fake_hcb! }

    it "returns orders scoped to the current user (admin sees all, so use non-admin)" do
      non_admin_user = create(:user, can_warehouse: true)
      non_admin_auth = Toolchest::AuthContext.new(
        resource_owner: non_admin_user,
        scopes: Toolchest.configuration.scopes.keys,
        token: nil
      )
      
      profile = create(:billing_profile, user: non_admin_user)
      sku = create(:warehouse_sku)
      template = Warehouse::Template.create!(name: "Test", user: non_admin_user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      
      my_order = Warehouse::Order.from_template(
        template, user: non_admin_user, recipient_email: "test@example.com",
        address: create(:address), billing_profile: profile
      ).tap(&:save!)
      
      other_user = create(:user, can_warehouse: true)
      other_profile = create(:billing_profile, user: other_user)
      other_template = Warehouse::Template.create!(name: "Other", user: other_user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      other_order = Warehouse::Order.from_template(
        other_template, user: other_user, recipient_email: "other@example.com",
        address: create(:address), billing_profile: other_profile
      ).tap(&:save!)
      
      response = Toolchest::Current.set(auth: non_admin_auth) do
        Toolchest.router.dispatch("warehouse_orders_search", {})
      end
      response = expect_success(response)
      data = JSON.parse(text_of(response))
      
      order_ids = data["orders"].map { |o| o["id"] }
      expect(order_ids).to include(my_order.hc_id)
      expect(order_ids).not_to include(other_order.hc_id)
    end

    it "filters by state" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      
      draft_order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test@example.com",
        address: create(:address), billing_profile: profile, aasm_state: "draft"
      ).tap(&:save!)
      
      dispatched_order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test2@example.com",
        address: create(:address), billing_profile: profile, aasm_state: "dispatched"
      ).tap(&:save!)
      
      response = expect_success(dispatch("warehouse_orders_search", { "state" => "draft" }))
      data = JSON.parse(text_of(response))
      
      order_ids = data["orders"].map { |o| o["id"] }
      expect(order_ids).to include(draft_order.hc_id)
      expect(order_ids).not_to include(dispatched_order.hc_id)
    end
  end

  describe "warehouse_orders show" do
    before { fake_hcb! }

    it "returns order details for the owner" do
      profile = create(:billing_profile, user: user)
      sku = create(:warehouse_sku)
      template = Warehouse::Template.create!(name: "Test", user: user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      order = Warehouse::Order.from_template(
        template, user: user, recipient_email: "test@example.com",
        address: create(:address), billing_profile: profile
      ).tap(&:save!)
      
      response = expect_success(dispatch("warehouse_orders_show", { "order_id" => order.hc_id }))
      data = JSON.parse(text_of(response))
      
      expect(data["id"]).to eq(order.hc_id)
      expect(data["line_items"]).to be_an(Array)
      expect(data["line_items"].length).to be > 0
    end

    it "blocks non-admin access to other users' orders" do
      other_user = create(:user)
      other_profile = create(:billing_profile, user: other_user)
      sku = create(:warehouse_sku)
      template = Warehouse::Template.create!(name: "Test", user: other_user, public: true)
        .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
      other_order = Warehouse::Order.from_template(
        template, user: other_user, recipient_email: "test@example.com",
        address: create(:address), billing_profile: other_profile
      ).tap(&:save!)
      
      # Switch to different non-admin user
      non_admin = create(:user)
      non_admin_auth = Toolchest::AuthContext.new(
        resource_owner: non_admin,
        scopes: Toolchest.configuration.scopes.keys,
        token: nil
      )
      
      response = Toolchest::Current.set(auth: non_admin_auth) do
        Toolchest.router.dispatch("warehouse_orders_show", { "order_id" => other_order.hc_id })
      end
      
      expect(response[:isError]).to be_truthy
    end
  end

  describe "return_addresses list" do
    it "returns only shared and owned addresses for non-admins" do
      non_admin = create(:user)
      non_admin_auth = Toolchest::AuthContext.new(
        resource_owner: non_admin,
        scopes: Toolchest.configuration.scopes.keys,
        token: nil
      )
      
      user_ra = create(:return_address, user: non_admin, shared: false)
      shared_ra = create(:return_address, user: create(:user), shared: true)
      other_private_ra = create(:return_address, user: create(:user), shared: false)
      
      response = Toolchest::Current.set(auth: non_admin_auth) do
        Toolchest.router.dispatch("return_addresses_list", {})
      end
      response = expect_success(response)
      data = JSON.parse(text_of(response))
      
      ra_ids = data["return_addresses"].map { |r| r["id"] }
      expect(ra_ids).to include(user_ra.id)
      expect(ra_ids).to include(shared_ra.id)
      expect(ra_ids).not_to include(other_private_ra.id)
    end

    it "returns all addresses for admin users" do
      user_ra = create(:return_address, user: user, shared: false)
      shared_ra = create(:return_address, user: create(:user), shared: true)
      other_private_ra = create(:return_address, user: create(:user), shared: false)
      
      response = expect_success(dispatch("return_addresses_list", {}))
      data = JSON.parse(text_of(response))
      
      ra_ids = data["return_addresses"].map { |r| r["id"] }
      expect(ra_ids).to include(user_ra.id)
      expect(ra_ids).to include(shared_ra.id)
      expect(ra_ids).to include(other_private_ra.id)  # Admin sees all
    end
  end

  describe "return_addresses show" do
    it "returns the address details for owned addresses" do
      ra = create(:return_address, user: user)
      
      response = expect_success(dispatch("return_addresses_show", { "return_address_id" => ra.id }))
      data = JSON.parse(text_of(response))
      
      expect(data["id"]).to eq(ra.id)
      expect(data["name"]).to eq(ra.name)
    end

    it "returns shared addresses to all users" do
      other_user = create(:user)
      shared_ra = create(:return_address, user: other_user, shared: true)
      
      response = expect_success(dispatch("return_addresses_show", { "return_address_id" => shared_ra.id }))
      data = JSON.parse(text_of(response))
      
      expect(data["id"]).to eq(shared_ra.id)
    end

    it "prevents IDOR - blocks access to other users' private addresses" do
      other_user = create(:user)
      private_ra = create(:return_address, user: other_user, shared: false)
      
      non_admin = create(:user)
      restricted_auth = Toolchest::AuthContext.new(
        resource_owner: non_admin,
        scopes: Toolchest.configuration.scopes.keys,
        token: nil
      )
      
      response = Toolchest::Current.set(auth: restricted_auth) do
        Toolchest.router.dispatch("return_addresses_show", { "return_address_id" => private_ra.id })
      end
      
      expect(response[:isError]).to be_truthy
    end
  end
end
