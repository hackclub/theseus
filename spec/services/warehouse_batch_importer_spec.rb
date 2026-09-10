# frozen_string_literal: true

require "rails_helper"

RSpec.describe WarehouseBatchImporter do
  let(:user) { create(:user, can_warehouse: true) }
  let(:mapping) do
    {
      "first_name" => "first_name", "last_name" => "last_name", "address" => "line_1",
      "city" => "city", "state" => "state", "zip" => "postal_code",
      "country" => "country", "email" => "email", "phone" => "phone_number"
    }
  end
  let(:header) { "first_name,last_name,address,city,state,zip,country,email,phone" }
  let(:csv_content) { ([ header ] + csv_rows).join("\n") + "\n" }
  let(:batch) { create(:warehouse_batch, user: user, csv_content: csv_content, mapping: mapping) }

  subject(:importer) { described_class.new(batch) }

  describe "#validate" do
    context "with a clean US row" do
      let(:csv_rows) { [ "Alice,Smith,123 Main St,Burlington,VT,05401,US,alice@example.com," ] }

      it "is valid" do
        expect(importer.validate).to eq([ { row: 0, status: :valid, errors: [], sample: "Alice Smith" } ])
      end
    end

    context "when the email is missing" do
      let(:csv_rows) { [ "Alice,Smith,123 Main St,Burlington,VT,05401,US,," ] }

      it "flags it, because every row becomes an order" do
        expect(importer.validate.first[:errors]).to include("Email blank")
      end
    end

    context "with an international row" do
      let(:csv_rows) do
        [
          "Bea,Jones,1 Rue de Rivoli,Paris,Île-de-France,75001,France,bea@example.com,",
          "Cal,Ng,2 Rue de Rivoli,Paris,Île-de-France,75001,France,cal@example.com,+33 1 23 45 67 89"
        ]
      end

      it "wants a phone number for customs" do
        results = importer.validate
        expect(results[0][:errors]).to include("Customs needs a phone number for France")
        expect(results[1][:status]).to eq(:valid)
      end
    end

    context "with countries the warehouse can't ship to" do
      let(:csv_rows) do
        [
          "Dan,Ivanov,1 Tverskaya,Moscow,Moscow,101000,Russia,dan@example.com,+7 495 000 0000",
          "Eve,Kim,1 Street,Pyongyang,Pyongyang,00000,North Korea,eve@example.com,+850 2 000 0000"
        ]
      end

      it "flags both the USPS list and the warehouse's own list" do
        results = importer.validate
        expect(results[0][:errors]).to include("We can't ship to Russian Federation from the warehouse")
        expect(results[1][:errors]).to include("We can't ship to North Korea from the warehouse")
      end
    end
  end

  describe "#call" do
    let(:csv_rows) do
      [
        "Alice,Smith,123 Main St,Burlington,VT,05401,US,alice@example.com,",
        "Cal,Ng,2 Rue de Rivoli,Paris,Île-de-France,75001,France,cal@example.com,+33 1 23 45 67 89"
      ]
    end

    it "creates addresses only and moves the batch to fields_mapped" do
      expect { importer.call }.to change { batch.addresses.count }.by(2).and change { Warehouse::Order.count }.by(0)
      expect(batch.reload).to be_fields_mapped
      expect(batch.addresses.find_by(first_name: "Cal")).to have_attributes(country: "FR", state: "IDF", phone_number: "+33 1 23 45 67 89", email: "cal@example.com")
    end

    context "with a broken row in the middle" do
      let(:csv_rows) { super().insert(1, "Bad,Row,,Nowhere,VT,05401,US,bad@example.com,") }

      it "raises rather than importing half a batch" do
        expect { importer.call }.to raise_error(ActiveRecord::RecordInvalid)
        expect(batch.reload.addresses).to be_empty
      end

      it "skips invalid rows when asked" do
        expect(importer.call(skip_invalid: true)).to eq(2)
        expect(batch.addresses.pluck(:first_name)).to contain_exactly("Alice", "Cal")
      end
    end
  end
end
