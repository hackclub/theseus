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
end
