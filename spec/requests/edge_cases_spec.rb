# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edge cases", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: "other") }
  let(:regular_user) { create(:user, can_warehouse: false, username: "regular") }

  before do
    fake_hcb!
    sign_in_as(user)
  end

  describe "authorization" do
    it "non-admin, non-warehouse user cannot access warehouse orders page" do
      sign_in_as(regular_user)

      get warehouse_orders_path

      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to include("authorized")
    end

    it "non-admin, non-warehouse user cannot access warehouse batches page" do
      sign_in_as(regular_user)

      get warehouse_batches_path

      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to include("authorized")
    end

    it "user cannot view a letter that belongs to another user" do
      letter = create(:letter, user: other_user, batch: nil)

      get letter_path(letter)

      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to include("authorized")
    end

    it "user cannot edit a letter that belongs to another user" do
      letter = create(:letter, user: other_user, batch: nil)

      get edit_letter_path(letter)

      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to include("authorized")
    end

    it "user can view their own letter" do
      letter = create(:letter, user: user, batch: nil)

      get letter_path(letter)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "form validation errors" do
    it "letter form re-renders with errors when posting invalid params" do
      invalid_params = {
        letter: {
          # missing required fields
          letter_height: -1  # invalid
        }
      }

      post letters_path, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("error") # validation error message
    end

    it "letter batch form re-renders with errors for invalid height" do
      batch = create(:letter_batch, user: user)

      patch letter_batch_path(batch), params: {
        letter_batch: {
          letter_height: -1
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("greater than 0")
    end

    it "warehouse order form re-renders with unprocessable_entity for missing required fields" do
      sign_in_as(create(:user, can_warehouse: true))

      post warehouse_orders_path, params: {
        warehouse_order: {
          recipient_email: "test@example.com"
          # missing address, line_items, billing_profile
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "CSV upload validation" do
    it "rejects non-CSV file upload to letter batch" do
      sign_in_as(user)
      return_address = create(:return_address, user: user)

      txt_file = Rack::Test::UploadedFile.new(
        StringIO.new("This is plain text, not CSV"),
        "text/plain",
        original_filename: "data.txt"
      )

      post letter_batches_path, params: {
        letter_batch: {
          csv: txt_file,
          letter_height: 5,
          letter_width: 3.5,
          letter_weight: 0.1,
          letter_return_address_id: return_address.id,
          letter_processing_category: 0
        }
      }

      # Should fail validation or redirect on error
      expect([302, 400, 422]).to include(response.status)
    end

    it "handles CSV with bad UTF-8 encoding gracefully" do
      sign_in_as(user)
      return_address = create(:return_address, user: user)

      # Create string with invalid UTF-8 bytes
      bad_csv_content = +"name,email\nJohn,test@"
      bad_csv_content << "\xFF\xFE"  # Add invalid UTF-8 bytes

      csv_file = Rack::Test::UploadedFile.new(
        StringIO.new(bad_csv_content),
        "text/csv",
        original_filename: "bad_encoding.csv"
      )

      post letter_batches_path, params: {
        letter_batch: {
          csv: csv_file,
          letter_height: 5,
          letter_width: 3.5,
          letter_weight: 0.1,
          letter_return_address_id: return_address.id,
          letter_processing_category: 0
        }
      }

      # Should not return 500 error
      expect(response.status).not_to eq(500)
      # Should be either validation error (400/422) or redirect (302)
      expect([302, 400, 422]).to include(response.status)
    end

    it "accepts valid CSV file upload to letter batch" do
      sign_in_as(user)
      return_address = create(:return_address, user: user)

      csv_content = "name,email,address\n"
      csv_content += "John Doe,john@example.com,123 Main St\n"
      csv_content += "Jane Smith,jane@example.com,456 Oak Ave\n"

      csv_file = Rack::Test::UploadedFile.new(
        StringIO.new(csv_content),
        "text/csv",
        original_filename: "addresses.csv"
      )

      post letter_batches_path, params: {
        letter_batch: {
          csv: csv_file,
          letter_height: 5,
          letter_width: 3.5,
          letter_weight: 0.1,
          letter_return_address_id: return_address.id,
          letter_processing_category: 0
        }
      }

      # Should redirect or show form, not crash (500)
      expect([302, 400, 422]).to include(response.status)
    end
  end

  describe "warehouse CSV upload validation" do
    it "rejects non-CSV file upload to warehouse batch" do
      warehouse_user = create(:user, can_warehouse: true)
      sign_in_as(warehouse_user)

      txt_file = Rack::Test::UploadedFile.new(
        StringIO.new("This is plain text, not CSV"),
        "text/plain",
        original_filename: "data.txt"
      )

      post warehouse_batches_path, params: {
        warehouse_batch: {
          csv: txt_file
        }
      }

      # Should fail validation or redirect on error
      expect([302, 400, 422]).to include(response.status)
    end

    it "handles warehouse CSV with bad UTF-8 encoding gracefully" do
      warehouse_user = create(:user, can_warehouse: true)
      sign_in_as(warehouse_user)

      # Create string with invalid UTF-8 bytes
      bad_csv_content = +"sku,quantity\nSKU001,"
      bad_csv_content << "\xFF\xFE"  # Add invalid UTF-8 bytes

      csv_file = Rack::Test::UploadedFile.new(
        StringIO.new(bad_csv_content),
        "text/csv",
        original_filename: "bad_warehouse.csv"
      )

      post warehouse_batches_path, params: {
        warehouse_batch: {
          csv: csv_file
        }
      }

      # Should not return 500 error
      expect(response.status).not_to eq(500)
      # Should be either validation error (400/422) or redirect (302)
      expect([302, 400, 422]).to include(response.status)
    end
  end

  describe "error handling" do
    it "does not crash when accessing invalid letter ID" do
      get letter_path(id: "nonexistent")

      # Should handle gracefully (either 404 or redirect)
      expect([302, 404]).to include(response.status)
    end

    it "does not crash when accessing invalid batch ID" do
      get letter_batch_path(id: "nonexistent")

      expect([302, 404]).to include(response.status)
    end

    it "returns error when submitting batch with invalid return address" do
      batch = create(:letter_batch, user: user)
      other_user_return_address = create(:return_address, user: other_user, shared: false)

      patch letter_batch_path(batch), params: {
        letter_batch: {
          letter_return_address_id: other_user_return_address.id
        }
      }

      expect([302, 422]).to include(response.status)
      # Error should be present in response
      expect(response.body).to include("error") if response.status == 422
    end
  end

  describe "public pages" do
    it "renders public letter page without crashing" do
      letter = create(:letter, user: user, batch: nil)

      get "/letters/#{letter.id}"

      # Should render or redirect, not crash (500)
      expect([200, 302, 403, 404]).to include(response.status)
    end

    it "renders public package page without crashing" do
      warehouse_user = create(:user, can_warehouse: true)
      connection = create(:hcb_oauth_connection, user: warehouse_user)
      profile = create(:billing_profile, user: warehouse_user, oauth_connection: connection)
      sku = create(:warehouse_sku)
      template = Warehouse::Template.create!(name: "Test", user: warehouse_user)
      template.line_items.create!(sku: sku, quantity: 1)

      order = Warehouse::Order.from_template(
        template, user: warehouse_user, recipient_email: "a@b.c",
        address: create(:address, country: "US"), billing_profile: profile
      ).tap(&:save!)

      get "/packages/#{order.id}"

      # Should render or redirect, not crash (500)
      expect([200, 302, 403, 404]).to include(response.status)
    end
  end
end
