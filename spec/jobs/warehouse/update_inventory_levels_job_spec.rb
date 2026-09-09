require "rails_helper"

RSpec.describe Warehouse::UpdateInventoryLevelsJob, type: :job do
  def inventory_item(sku_code, sellable:, inbound: 0, id: rand(100_000..999_999))
    { item: { sku: sku_code, id: id }, sellable: sellable, inbound: inbound }
  end

  def po(id:, items:)
    { id: id, orderNumber: "PO-#{id}", items: items }
  end

  def po_item(sku_code, quantity:, unit_cost:)
    { sku: sku_code, quantity: quantity, unitCost: unit_cost }
  end

  let(:alert_mailer) { double("alert_mailer") }

  before do
    allow(Warehouse::InventoryAlertMailer).to receive(:cost_alert).and_return(alert_mailer)
    allow(alert_mailer).to receive(:deliver_later)
    allow(Zenventory).to receive(:get_items).and_return([])
  end

  describe "happy path" do
    let!(:sku_a) { create(:warehouse_sku, sku: "Har/Good/One", enabled: true) }
    let!(:sku_b) { create(:warehouse_sku, sku: "Har/Good/Two", enabled: true) }

    before do
      allow(Zenventory).to receive(:get_inventory).and_return([
        inventory_item("Har/Good/One", sellable: 50, inbound: 10, id: 1001),
        inventory_item("Har/Good/Two", sellable: 25, inbound: 0, id: 1002),
      ])

      allow(Zenventory).to receive(:get_purchase_orders).and_return([
        po(id: 100, items: [
          po_item("Har/Good/One", quantity: 20, unit_cost: 10.0),
          po_item("Har/Good/Two", quantity: 50, unit_cost: 5.0),
        ]),
        po(id: 101, items: [
          po_item("Har/Good/One", quantity: 30, unit_cost: 15.0),
        ]),
      ])
    end

    it "updates inventory levels from zenventory" do
      described_class.perform_now

      sku_a.reload
      expect(sku_a.in_stock).to eq(50)
      expect(sku_a.inbound).to eq(10)
      expect(sku_a.zenventory_id).to eq("1001")

      sku_b.reload
      expect(sku_b.in_stock).to eq(25)
      expect(sku_b.inbound).to be_nil # nilified: 0 → nil
    end

    it "calculates weighted average PO cost" do
      described_class.perform_now

      # sku_a: (20*10 + 30*15) / (20+30) = 650/50 = 13.0
      expect(sku_a.reload.average_po_cost.to_f).to eq(13.0)
      # sku_b: (50*5) / 50 = 5.0
      expect(sku_b.reload.average_po_cost.to_f).to eq(5.0)
    end

    it "does not send an alert email" do
      described_class.perform_now
      expect(Warehouse::InventoryAlertMailer).not_to have_received(:cost_alert)
    end
  end

  describe "zero-cost PO items" do
    let!(:sku) { create(:warehouse_sku, sku: "Har/Bad/Zero", enabled: true) }

    before do
      allow(Zenventory).to receive(:get_inventory).and_return([
        inventory_item("Har/Bad/Zero", sellable: 10, id: 2001),
      ])
    end

    context "when all PO items have zero cost" do
      before do
        allow(Zenventory).to receive(:get_purchase_orders).and_return([
          po(id: 200, items: [
            po_item("Har/Bad/Zero", quantity: 23, unit_cost: 0),
          ]),
        ])
      end

      it "writes nil instead of 0.0 to average_po_cost" do
        described_class.perform_now
        expect(sku.reload.average_po_cost).to be_nil
      end

      it "does not send an alert email for historic zero-cost PO data" do
        described_class.perform_now
        expect(Warehouse::InventoryAlertMailer).not_to have_received(:cost_alert)
      end
    end

    context "when some PO items have zero cost and some don't" do
      before do
        allow(Zenventory).to receive(:get_purchase_orders).and_return([
          po(id: 200, items: [
            po_item("Har/Bad/Zero", quantity: 10, unit_cost: 0),
          ]),
          po(id: 201, items: [
            po_item("Har/Bad/Zero", quantity: 20, unit_cost: 8.0),
          ]),
        ])
      end

      it "calculates average from only the good items" do
        described_class.perform_now
        # only the 20 units at $8: 160/20 = 8.0
        expect(sku.reload.average_po_cost.to_f).to eq(8.0)
      end

      it "does not send an alert email when good PO data covers the SKU" do
        described_class.perform_now
        expect(Warehouse::InventoryAlertMailer).not_to have_received(:cost_alert)
      end
    end
  end

  describe "costless enabled SKUs" do
    let!(:costless_sku) { create(:warehouse_sku, sku: "Har/No/Cost", enabled: true) }
    let!(:disabled_sku) { create(:warehouse_sku, sku: "Har/No/Cost2", enabled: false) }

    before do
      allow(Zenventory).to receive(:get_inventory).and_return([
        inventory_item("Har/No/Cost", sellable: 5, id: 3001),
        inventory_item("Har/No/Cost2", sellable: 5, id: 3002),
      ])
      allow(Zenventory).to receive(:get_purchase_orders).and_return([])
    end

    it "flags enabled SKUs with no cost data" do
      described_class.perform_now

      expect(Warehouse::InventoryAlertMailer).to have_received(:cost_alert) do |args|
        costless = args[:costless_skus].map(&:sku)
        expect(costless).to include("Har/No/Cost")
      end
    end

    it "does not flag disabled SKUs" do
      described_class.perform_now

      expect(Warehouse::InventoryAlertMailer).to have_received(:cost_alert) do |args|
        costless = args[:costless_skus].map(&:sku)
        expect(costless).not_to include("Har/No/Cost2")
      end
    end
  end

  describe "costless SKUs with no inventory and nothing incoming" do
    let!(:sku) { create(:warehouse_sku, sku: "Har/No/Stock", enabled: true) }

    before do
      allow(Zenventory).to receive(:get_purchase_orders).and_return([])
    end

    context "when there's no stock and nothing inbound" do
      before do
        allow(Zenventory).to receive(:get_inventory).and_return([
          inventory_item("Har/No/Stock", sellable: 0, inbound: 0, id: 5001),
        ])
      end

      it "does not send an alert" do
        described_class.perform_now
        expect(Warehouse::InventoryAlertMailer).not_to have_received(:cost_alert)
      end
    end

    context "when there's stock on hand" do
      before do
        allow(Zenventory).to receive(:get_inventory).and_return([
          inventory_item("Har/No/Stock", sellable: 5, inbound: 0, id: 5002),
        ])
      end

      it "sends an alert" do
        described_class.perform_now
        expect(Warehouse::InventoryAlertMailer).to have_received(:cost_alert) do |args|
          expect(args[:costless_skus].map(&:sku)).to include("Har/No/Stock")
        end
      end
    end

    context "when there's nothing on hand but a PO is inbound" do
      before do
        allow(Zenventory).to receive(:get_inventory).and_return([
          inventory_item("Har/No/Stock", sellable: 0, inbound: 10, id: 5003),
        ])
      end

      it "sends an alert" do
        described_class.perform_now
        expect(Warehouse::InventoryAlertMailer).to have_received(:cost_alert) do |args|
          expect(args[:costless_skus].map(&:sku)).to include("Har/No/Stock")
        end
      end
    end
  end

  describe "falling back to zenventory's default unit cost" do
    let!(:sku) { create(:warehouse_sku, sku: "Har/Default/Cost", enabled: true) }

    before do
      allow(Zenventory).to receive(:get_inventory).and_return([
        inventory_item("Har/Default/Cost", sellable: 5, id: 6001),
      ])
    end

    context "when there are no POs to average" do
      before do
        allow(Zenventory).to receive(:get_purchase_orders).and_return([])
        allow(Zenventory).to receive(:get_items).and_return([
          { sku: "Har/Default/Cost", unitCost: 12.5 },
        ])
      end

      it "uses the zenventory default unit cost" do
        described_class.perform_now
        expect(sku.reload.average_po_cost.to_f).to eq(12.5)
      end

      it "does not send an alert" do
        described_class.perform_now
        expect(Warehouse::InventoryAlertMailer).not_to have_received(:cost_alert)
      end
    end

    context "when the zenventory default unit cost is zero" do
      before do
        allow(Zenventory).to receive(:get_purchase_orders).and_return([])
        allow(Zenventory).to receive(:get_items).and_return([
          { sku: "Har/Default/Cost", unitCost: 0 },
        ])
      end

      it "leaves average_po_cost nil and still alerts" do
        described_class.perform_now
        expect(sku.reload.average_po_cost).to be_nil
        expect(Warehouse::InventoryAlertMailer).to have_received(:cost_alert)
      end
    end

    context "when there's already a PO-based average" do
      before do
        allow(Zenventory).to receive(:get_purchase_orders).and_return([
          po(id: 600, items: [po_item("Har/Default/Cost", quantity: 10, unit_cost: 3.0)]),
        ])
        allow(Zenventory).to receive(:get_items).and_return([
          { sku: "Har/Default/Cost", unitCost: 99.0 },
        ])
      end

      it "prefers the real PO average over the default" do
        described_class.perform_now
        expect(sku.reload.average_po_cost.to_f).to eq(3.0)
      end
    end
  end

  describe "SKU with override" do
    let!(:sku) { create(:warehouse_sku, sku: "Har/Override", enabled: true, declared_unit_cost_override: 99.0) }

    before do
      allow(Zenventory).to receive(:get_inventory).and_return([
        inventory_item("Har/Override", sellable: 1, id: 4001),
      ])
      allow(Zenventory).to receive(:get_purchase_orders).and_return([
        po(id: 400, items: [
          po_item("Har/Override", quantity: 5, unit_cost: 0),
        ]),
      ])
    end

    it "does not send an alert email when override covers the SKU" do
      described_class.perform_now
      expect(Warehouse::InventoryAlertMailer).not_to have_received(:cost_alert)
    end
  end

  describe "SKU not in warehouse inventory" do
    let!(:orphan_sku) { create(:warehouse_sku, sku: "Har/Orphan", enabled: true) }

    before do
      allow(Zenventory).to receive(:get_inventory).and_return([])
      allow(Zenventory).to receive(:get_purchase_orders).and_return([])
    end

    it "skips the SKU without crashing" do
      expect { described_class.perform_now }.not_to raise_error
    end

    it "does not update the SKU" do
      described_class.perform_now
      expect(orphan_sku.reload.in_stock).to be_nil
    end
  end
end
