# frozen_string_literal: true

require "rails_helper"

RSpec.describe LetterBatchImporter do
  let(:user) { create(:user) }
  let(:mailer_id) { create(:usps_mailer_id) }
  let(:return_address) { create(:return_address) }

  let(:csv_content) { csv_rows.join("\n") + "\n" }
  let(:mapping) do
    {
      "first_name" => "first_name",
      "last_name" => "last_name",
      "address" => "line_1",
      "city" => "city",
      "state" => "state",
      "zip" => "postal_code",
    }
  end

  let(:batch) do
    create(:letter_batch,
      user: user,
      mailer_id: mailer_id,
      csv_content: csv_content,
      mapping: mapping)
  end

  subject(:importer) { described_class.new(batch) }

  # ── #validate ──────────────────────────────────────────────────────

  describe "#validate" do
    context "with all required fields" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,05401",
        ]
      end

      it "returns :valid for each row" do
        results = importer.validate
        expect(results.length).to eq(1)
        expect(results.first[:status]).to eq(:valid)
        expect(results.first[:errors]).to be_empty
      end
    end

    context "when first_name is missing" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          ",Smith,123 Main St,Burlington,VT,05401",
        ]
      end

      it "returns :error" do
        results = importer.validate
        expect(results.first[:status]).to eq(:error)
        expect(results.first[:errors]).to include("First name blank")
      end
    end

    context "when line_1 (address) is missing" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,,Burlington,VT,05401",
        ]
      end

      it "returns :error" do
        results = importer.validate
        expect(results.first[:status]).to eq(:error)
        expect(results.first[:errors]).to include("Address blank")
      end
    end

    context "when postal_code is missing" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,",
        ]
      end

      it "returns :error" do
        results = importer.validate
        expect(results.first[:status]).to eq(:error)
        expect(results.first[:errors]).to include("ZIP blank")
      end
    end

    context "with garbage ZIP (single digit)" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,5",
        ]
      end

      it "returns :error with invalid ZIP message" do
        results = importer.validate
        expect(results.first[:status]).to eq(:error)
        expect(results.first[:errors]).to include(a_string_matching(/ZIP looks invalid/))
      end
    end

    context "does not create any records" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,05401",
        ]
      end

      it "leaves Address and Letter counts unchanged" do
        # Materialize batch first so its creation doesn't affect counts
        batch

        expect { importer.validate }.to change { Address.count }.by(0)
          .and change { Letter.count }.by(0)
      end
    end

    context "returns correct row indices for errors" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,05401",
          ",Smith,456 Oak Ave,Burlington,VT,05401",
          "Bob,Jones,789 Elm St,Burlington,VT,05401",
        ]
      end

      it "marks the correct row index as :error" do
        results = importer.validate
        expect(results[0][:status]).to eq(:valid)
        expect(results[0][:row]).to eq(0)
        expect(results[1][:status]).to eq(:error)
        expect(results[1][:row]).to eq(1)
        expect(results[2][:status]).to eq(:valid)
        expect(results[2][:row]).to eq(2)
      end
    end
  end

  # ── #call ──────────────────────────────────────────────────────────

  describe "#call" do
    context "with valid rows" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,05401",
          "Bob,Jones,456 Oak Ave,Montpelier,VT,05602",
        ]
      end

      it "creates addresses and letters for each row" do
        expect { importer.call }
          .to change { Address.count }.by(2)
          .and change { Letter.count }.by(2)
      end

      it "sets correct address fields from CSV mapping" do
        importer.call
        address = batch.addresses.first

        expect(address.first_name).to eq("Alice")
        expect(address.last_name).to eq("Smith")
        expect(address.line_1).to eq("123 Main St")
        expect(address.city).to eq("Burlington")
        expect(address.state).to eq("VT")
        expect(address.postal_code).to eq("05401")
      end

      it "returns the count of imported letters" do
        expect(importer.call).to eq(2)
      end
    end

    context "ZIP normalization" do
      let(:mapping) do
        {
          "first_name" => "first_name",
          "last_name" => "last_name",
          "address" => "line_1",
          "city" => "city",
          "state" => "state",
          "zip" => "postal_code",
          "country" => "country",
        }
      end

      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip,country",
          "Alice,Smith,123 Main St,Burlington,VT,123,US",
        ]
      end

      it "pads short US ZIPs to 5 digits" do
        importer.call
        address = batch.addresses.first
        expect(address.postal_code).to eq("00123")
      end
    end

    context "when no country column in CSV" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "Alice,Smith,123 Main St,Burlington,VT,05401",
        ]
      end

      it "defaults country to US" do
        importer.call
        address = batch.addresses.first
        expect(address.country).to eq("US")
      end
    end

    context "when first_name is blank" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          ",Smith,123 Main St,Burlington,VT,05401",
          "Bob,Jones,456 Oak Ave,Burlington,VT,05401",
        ]
      end

      it "skips the blank-name row and imports only the valid one" do
        expect(importer.call).to eq(1)
        expect(batch.addresses.count).to eq(1)
        expect(batch.addresses.first.first_name).to eq("Bob")
      end
    end
  end

  # ── #call(skip_invalid: true) ──────────────────────────────────────

  describe "#call(skip_invalid: true)" do
    let(:csv_rows) do
      [
        "first_name,last_name,address,city,state,zip",
        "Alice,Smith,123 Main St,Burlington,VT,05401",
        "Bob,Jones,,Burlington,VT,05401",
        "Carol,Lee,789 Elm St,Burlington,VT,05401",
      ]
    end

    it "imports valid rows and skips invalid ones" do
      expect { importer.call(skip_invalid: true) }
        .to change { Address.count }.by(2)
        .and change { Letter.count }.by(2)
    end

    it "returns count of only the valid rows imported" do
      expect(importer.call(skip_invalid: true)).to eq(2)
    end

    it "does not raise on invalid rows" do
      expect { importer.call(skip_invalid: true) }.not_to raise_error
    end
  end

  # ── Edge cases ─────────────────────────────────────────────────────

  describe "edge cases" do
    context "CSV with extra columns not in mapping" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip,favorite_color,shoe_size",
          "Alice,Smith,123 Main St,Burlington,VT,05401,blue,9",
        ]
      end

      it "ignores extra columns and imports normally" do
        expect(importer.call).to eq(1)
        expect(batch.addresses.first.first_name).to eq("Alice")
      end
    end

    context "mapping with empty string values (unmapped columns)" do
      let(:mapping) do
        {
          "first_name" => "first_name",
          "last_name" => "last_name",
          "address" => "line_1",
          "city" => "city",
          "state" => "state",
          "zip" => "postal_code",
          "extra_col" => "",
        }
      end

      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip,extra_col",
          "Alice,Smith,123 Main St,Burlington,VT,05401,ignored",
        ]
      end

      it "treats empty-string mapping values as unmapped" do
        expect(importer.call).to eq(1)
        expect(batch.addresses.first.first_name).to eq("Alice")
      end
    end

    context "unicode gremlins and whitespace in field values" do
      let(:csv_rows) do
        [
          "first_name,last_name,address,city,state,zip",
          "  Ali\u200Ece  , Sm\u200Bith , 123 Main St , Burlington , VT , 05401 ",
        ]
      end

      it "strips whitespace and removes gremlin characters" do
        importer.call
        address = batch.addresses.first

        expect(address.first_name).to eq("Alice")
        expect(address.last_name).to eq("Smith")
        expect(address.line_1).to eq("123 Main St")
      end
    end
  end
end
