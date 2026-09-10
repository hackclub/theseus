# frozen_string_literal: true

require "rails_helper"

RSpec.describe "warehouse batches", type: :request do
  let(:user) { create(:user, can_warehouse: true) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }
  let(:template) do
    Warehouse::Template.create!(name: "Sticker pack", user: user, public: true)
                       .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
  end
  let(:header) { "first_name,last_name,address,city,state,zip,country,email,phone" }
  let(:mapping) do
    {
      "first_name" => "first_name", "last_name" => "last_name", "address" => "line_1", "city" => "city",
      "state" => "state", "zip" => "postal_code", "country" => "country", "email" => "email", "phone" => "phone_number"
    }
  end
  let(:good_row) { "Alice,Smith,123 Main St,Burlington,VT,05401,US,alice@example.com," }
  let(:bad_row) { "Bea,Jones,1 Rue de Rivoli,Paris,Île-de-France,75001,France,bea@example.com," }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  def upload(rows)
    Rack::Test::UploadedFile.new(StringIO.new(([ header ] + rows).join("\n") + "\n"), "text/csv", original_filename: "addresses.csv")
  end

  describe "the CSV flow" do
    it "uploads, maps, imports, and lands on the process page" do
      profile
      post warehouse_batches_path, params: { batch: { warehouse_template_id: template.id, csv: upload([ good_row ]) } }
      batch = Warehouse::Batch.last
      expect(response).to redirect_to(map_fields_warehouse_batch_path(batch))
      expect(batch).to be_awaiting_field_mapping

      get map_fields_warehouse_batch_path(batch)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Map CSV Fields").and include("field_mapping[email]")

      post set_mapping_warehouse_batch_path(batch), params: { field_mapping: mapping }
      expect(response).to redirect_to(process_confirm_warehouse_batch_path(batch))
      expect(batch.reload).to be_fields_mapped
      expect(batch.addresses.pluck(:email)).to eq([ "alice@example.com" ])

      get process_confirm_warehouse_batch_path(batch)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Process Batch").and include("labor for 1 order")
    end

    it "refuses a batch with no CSV" do
      post warehouse_batches_path, params: { batch: { warehouse_template_id: template.id } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Csv must be uploaded")
    end

    it "shows the validate page when rows are bad, then imports the good ones on request" do
      post warehouse_batches_path, params: { batch: { warehouse_template_id: template.id, csv: upload([ good_row, bad_row ]) } }
      batch = Warehouse::Batch.last

      post set_mapping_warehouse_batch_path(batch), params: { field_mapping: mapping }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1 invalid").and include("Customs needs a phone number for France")
      expect(batch.addresses).to be_empty

      post import_with_skip_warehouse_batch_path(batch)
      expect(response).to redirect_to(process_confirm_warehouse_batch_path(batch))
      expect(batch.reload.addresses.pluck(:first_name)).to eq([ "Alice" ])
    end
  end

  describe "re-importing" do
    it "refuses a second set_mapping or import_with_skip once the batch is imported" do
      post warehouse_batches_path, params: { batch: { warehouse_template_id: template.id, csv: upload([ good_row ]) } }
      batch = Warehouse::Batch.last

      post set_mapping_warehouse_batch_path(batch), params: { field_mapping: mapping }
      expect(batch.reload.addresses.count).to eq(1)

      post set_mapping_warehouse_batch_path(batch), params: { field_mapping: mapping }
      expect(response).to redirect_to(warehouse_batch_path(batch))
      expect(flash[:alert]).to include("already been imported")

      post import_with_skip_warehouse_batch_path(batch)
      expect(response).to redirect_to(warehouse_batch_path(batch))
      expect(flash[:alert]).to include("already been imported")

      expect(batch.reload.addresses.count).to eq(1)
    end
  end

  describe "the process page" do
    let(:batch) { create(:warehouse_batch, user: user, warehouse_template: template, billing_profile: profile, mapping: mapping) }

    it "blocks processing when preflight finds an unmailable row" do
      batch.addresses.create!(first_name: "Dan", last_name: "I", line_1: "1 Tverskaya", city: "Moscow", state: "Moscow", postal_code: "101000", country: "RU", email: "dan@example.com")
      batch.mark_fields_mapped!

      get process_confirm_warehouse_batch_path(batch)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("shipped yet").and include("Russian Federation")
      expect(response.body).not_to include("batch[hcb_payment_account_id]")
    end

    it "sends an already-processed batch back to the batch with a message" do
      batch.addresses.create!(first_name: "Alice", last_name: "S", line_1: "1 Main St", city: "Burlington", state: "VT", postal_code: "05401", country: "US", email: "alice@example.com")
      batch.update!(aasm_state: "processed")

      get process_confirm_warehouse_batch_path(batch)
      expect(response).to redirect_to(warehouse_batch_path(batch))
      expect(flash[:alert]).to include("already been processed")

      post process_batch_warehouse_batch_path(batch)
      expect(response).to redirect_to(warehouse_batch_path(batch))
      expect(flash[:alert]).to include("already been processed")
    end

    it "re-renders the page instead of raising when process! fails" do
      batch.mark_fields_mapped!
      allow_any_instance_of(Warehouse::Batch).to receive(:process!) { |b| b.errors.add(:base, "nope"); false }

      post process_batch_warehouse_batch_path(batch)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("nope")
    end
  end

  describe "editing" do
    let(:batch) { create(:warehouse_batch, user: user, warehouse_template: template) }

    it "re-renders the edit form with the template list when the update fails" do
      allow_any_instance_of(Warehouse::Batch).to receive(:update) { |b, *| b.errors.add(:base, "nope"); false }

      patch warehouse_batch_path(batch), params: { batch: { warehouse_user_facing_title: "x" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("nope").and include("Sticker pack")
    end
  end

  describe "authorization" do
    let(:batch) { create(:warehouse_batch, user: user, warehouse_template: template) }

    it "does not let a non-admin owner delete their own batch" do
      delete warehouse_batch_path(batch)
      expect(response).to redirect_to(root_path)
      expect(Warehouse::Batch.exists?(batch.id)).to be(true)
    end

    it "lets an admin delete a batch" do
      sign_in_as(create_admin)
      delete warehouse_batch_path(batch)
      expect(response).to redirect_to(warehouse_batches_path)
      expect(Warehouse::Batch.exists?(batch.id)).to be(false)
    end

    it "keeps every warehouse batch action working for an admin" do
      admin = create_admin
      sign_in_as(admin)
      admin_profile = create(:billing_profile, user: admin)
      admin_batch = create(:warehouse_batch, user: admin, warehouse_template: template, billing_profile: admin_profile)
      allow(Zenventory).to receive(:create_customer_order).and_return({ id: 42 })

      get warehouse_batches_path
      expect(response).to have_http_status(:ok)

      get new_warehouse_batch_path
      expect(response).to have_http_status(:ok)

      get warehouse_batch_path(admin_batch)
      expect(response).to have_http_status(:ok)

      get edit_warehouse_batch_path(admin_batch)
      expect(response).to have_http_status(:ok)

      get map_fields_warehouse_batch_path(admin_batch)
      expect(response).to have_http_status(:ok)

      post set_mapping_warehouse_batch_path(admin_batch), params: { field_mapping: { "first_name" => "first_name", "last_name" => "last_name", "address" => "line_1", "city" => "city", "state" => "state", "zip" => "postal_code", "email" => "email" } }
      expect(response).to redirect_to(process_confirm_warehouse_batch_path(admin_batch))
      expect(admin_batch.reload).to be_fields_mapped

      patch warehouse_batch_path(admin_batch), params: { batch: { warehouse_user_facing_title: "stickers" } }
      expect(response).to redirect_to(warehouse_batch_path(admin_batch))

      get process_confirm_warehouse_batch_path(admin_batch)
      expect(response).to have_http_status(:ok)

      post process_batch_warehouse_batch_path(admin_batch), params: { batch: { hcb_payment_account_id: admin_profile.id } }
      expect(response).to redirect_to(warehouse_batch_path(admin_batch))
      expect(admin_batch.reload).to be_processed
    end
  end
end
