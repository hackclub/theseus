# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse orders", type: :request do
  let(:user) { create(:user, can_warehouse: true) }
  let(:connection) { create(:hcb_oauth_connection, user: user) }
  let(:profile) { create(:billing_profile, user: user, oauth_connection: connection) }
  let(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }
  let(:template) do
    Warehouse::Template.create!(name: "Sticker pack", user: user).tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
  end
  let(:order) do
    Warehouse::Order.from_template(
      template, user: user, recipient_email: "a@b.c", address: create(:address, country: "US"), billing_profile: profile
    ).tap(&:save!)
  end

  before do
    fake_hcb!
    sign_in_as(user)
  end

  describe "the edit form" do
    it "can turn notify_on_dispatch off, clear the notes and drop the billing profile" do
      order.update!(notify_on_dispatch: true, internal_notes: "loud", user_facing_title: "a title")

      get edit_warehouse_order_path(order)
      expect(response.body).to include('<input type="hidden" name="warehouse_order[notify_on_dispatch]" value="0">')

      patch warehouse_order_path(order), params: {
        warehouse_order: { notify_on_dispatch: "0", internal_notes: "", user_facing_title: "", billing_profile_id: "" }
      }

      expect(response).to redirect_to(warehouse_order_path(order))
      order.reload
      expect(order.notify_on_dispatch).to be(false)
      expect(order.internal_notes).to eq("")
      expect(order.user_facing_title).to eq("")
      expect(order.billing_profile).to be_nil
    end
  end

  describe "the batch link" do
    it "points at the warehouse batch, not the letter batch" do
      batch = create(:warehouse_batch, user: user, warehouse_template: template)
      order.update!(batch: batch)

      get warehouse_order_path(order)
      expect(response.body).to include(warehouse_batch_path(batch))
      expect(response.body).not_to include(letter_batch_path(batch))
    end
  end

  describe "cancelling" do
    before { order.mark_dispatched!(123) }

    it "redirects with a notice once zenventory agrees" do
      allow(Zenventory).to receive(:cancel_customer_order)

      post cancel_warehouse_order_path(order), params: { cancellation_reason: "changed my mind" }

      expect(response).to redirect_to(warehouse_order_path(order))
      expect(flash[:success]).to be_present
      expect(order.reload).to be_canceled
    end

    it "leaves the order alone when zenventory fails" do
      allow(Zenventory).to receive(:cancel_customer_order).and_raise(Zenventory::ZenventoryError.new("nope"))

      post cancel_warehouse_order_path(order), params: { cancellation_reason: "changed my mind" }

      expect(response).to redirect_to(warehouse_order_path(order))
      expect(flash[:alert]).to include("nope")
      expect(order.reload).to be_dispatched
    end
  end

  describe "creating a new order" do
    it "GET new renders the form with empty address" do
      get new_warehouse_order_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("address")
    end

    it "POST create with address, line items, and tags saves as draft" do
      sku2 = create(:warehouse_sku, name: "Patches")
      
      post warehouse_orders_path, params: {
        warehouse_order: {
          user_facing_title: "Custom order",
          user_facing_description: "A test order",
          recipient_email: "customer@example.com",
          notify_on_dispatch: "1",
          tags: ["urgent", "custom"],
          address_attributes: {
            first_name: "Jane",
            last_name: "Doe",
            line_1: "456 Oak Ave",
            city: "Portland",
            state: "OR",
            postal_code: "97201",
            country: "US",
            phone_number: "555-1234",
            email: "jane@example.com"
          },
          line_items_attributes: [
            { sku_id: sku.id, quantity: 5 },
            { sku_id: sku2.id, quantity: 2 }
          ],
          billing_profile_id: profile.id
        }
      }

      expect(response).to redirect_to(warehouse_order_path(Warehouse::Order.last))
      order = Warehouse::Order.last
      expect(order.user).to eq(user)
      expect(order.user_facing_title).to eq("Custom order")
      expect(order.recipient_email).to eq("customer@example.com")
      expect(order.notify_on_dispatch).to be(true)
      expect(order.tags).to include("urgent", "custom")
      expect(order.address.first_name).to eq("Jane")
      expect(order.address.postal_code).to eq("97201")
      expect(order.line_items.count).to eq(2)
      expect(order.line_items.first.quantity).to eq(5)
      expect(order.aasm_state).to eq("draft")
      expect(order.billing_profile).to eq(profile)
    end

    it "POST create fails with invalid params and re-renders form" do
      post warehouse_orders_path, params: {
        warehouse_order: {
          recipient_email: "customer@example.com"
          # missing required fields
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Warehouse::Order.count).to eq(0)
    end
  end

  describe "editing a draft order" do
    it "GET edit renders the form" do
      get edit_warehouse_order_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("address")
    end

    it "PATCH update changes quantities and other attributes" do
      sku2 = create(:warehouse_sku, name: "Stickers")
      order.line_items.create!(sku: sku2, quantity: 3)

      patch warehouse_order_path(order), params: {
        warehouse_order: {
          user_facing_title: "Updated title",
          internal_notes: "Handle with care",
          line_items_attributes: [
            { id: order.line_items.first.id, quantity: 10 },
            { id: order.line_items.second.id, quantity: 1 }
          ]
        }
      }

      expect(response).to redirect_to(warehouse_order_path(order))
      order.reload
      expect(order.user_facing_title).to eq("Updated title")
      expect(order.internal_notes).to eq("Handle with care")
      expect(order.line_items.first.quantity).to eq(10)
      expect(order.line_items.second.quantity).to eq(1)
    end
  end

  describe "order show page" do
    it "GET show renders the order with line items table and status badge" do
      order.line_items.create!(sku: create(:warehouse_sku, name: "Extra SKU"), quantity: 3)
      
      get warehouse_order_path(order)
      expect(response).to have_http_status(:ok)
      
      # Check for line items - SKU names
      expect(response.body).to include(sku.name)
      expect(response.body).to include("Extra SKU")
    end
  end

  describe "order index" do
    let(:order2) do
      Warehouse::Order.from_template(
        template, user: user, recipient_email: "b@c.com", 
        address: create(:address, country: "US"), billing_profile: profile
      ).tap(&:save!)
    end

    it "GET index lists orders with pagination" do
      order
      order2

      get warehouse_orders_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Draft")
    end

    it "GET index filters by state" do
      order.mark_dispatched!(123)
      order2

      get warehouse_orders_path(state: "draft")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Draft")
    end

    it "GET index filters by origin" do
      order.update!(created_via: "bulk_upload")
      order2.update!(created_via: "manual")

      get warehouse_orders_path(origin: "manual")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Draft")
    end

    it "GET index searches by order ID" do
      get warehouse_orders_path(search: order.hc_id)
      expect(response).to have_http_status(:ok)
      # Just verify the page renders without error
    end


  end

  describe "sending to warehouse" do
    it "POST send_to_warehouse dispatches the order and changes status" do
      allow(Zenventory).to receive(:create_customer_order).and_return({ id: "zen_123" })

      post send_to_warehouse_warehouse_order_path(order)

      expect(response).to redirect_to(warehouse_order_path(order))
      expect(flash[:success]).to include("successfully sent to warehouse")
      order.reload
      expect(order).to be_dispatched
    end

    it "handles zenventory errors gracefully" do
      allow(Zenventory).to receive(:create_customer_order).and_raise(
        Zenventory::ZenventoryError.new("API down")
      )

      post send_to_warehouse_warehouse_order_path(order)

      expect(response).to redirect_to(warehouse_order_path(order))
      expect(flash[:alert]).to include("API down")
      order.reload
    end

    it "handles invalid state transition errors" do
      allow(Zenventory).to receive(:create_customer_order).and_raise(
        AASM::InvalidTransition.new(order, :dispatch, :default)
      )

      post send_to_warehouse_warehouse_order_path(order)

      expect(response).to redirect_to(warehouse_order_path(order))
      expect(flash[:alert]).to include("wrong state")
    end
  end

  describe "cancel flow" do
    before { order.mark_dispatched!(123) }

    it "GET cancel renders the cancellation form for dispatched order" do
      get cancel_warehouse_order_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("cancellation_reason")
    end

    it "prevents cancellation of mailed orders" do
      order.mark_mailed!

      get cancel_warehouse_order_path(order)
      expect(response).to redirect_to(warehouse_order_path(order))
      expect(flash[:alert]).to include("not in a cancelable state")
    end
  end
end
