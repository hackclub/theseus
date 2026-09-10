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
end
