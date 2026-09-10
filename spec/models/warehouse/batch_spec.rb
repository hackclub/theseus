# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  audit_log                   :jsonb
#  field_mapping               :jsonb
#  letter_height               :decimal(, )
#  letter_mailing_date         :date
#  letter_processing_category  :integer
#  letter_return_address_name  :string
#  letter_weight               :decimal(, )
#  letter_width                :decimal(, )
#  process_error               :string
#  process_options             :jsonb
#  tags                        :citext           default([]), is an Array
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  hcb_payment_account_id      :bigint
#  hcb_transfer_id             :string
#  letter_mailer_id_id         :bigint
#  letter_queue_id             :bigint
#  letter_return_address_id    :bigint
#  user_id                     :bigint           not null
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_aasm_state                (aasm_state)
#  index_batches_on_hcb_payment_account_id    (hcb_payment_account_id)
#  index_batches_on_letter_mailer_id_id       (letter_mailer_id_id)
#  index_batches_on_letter_queue_id           (letter_queue_id)
#  index_batches_on_letter_return_address_id  (letter_return_address_id)
#  index_batches_on_tags                      (tags) USING gin
#  index_batches_on_type                      (type)
#  index_batches_on_user_id                   (user_id)
#  index_batches_on_warehouse_template_id     (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_payment_account_id => hcb_payment_accounts.id)
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (letter_queue_id => letter_queues.id)
#  fk_rails_...  (letter_return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
RSpec.describe Warehouse::Batch do
  let(:user) { create(:user, can_warehouse: true) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:sku) { create(:warehouse_sku, declared_unit_cost_override: 2.0, actual_cost_to_hc: 1.0) }
  let(:template) do
    Warehouse::Template.create!(name: "Sticker pack", user: user, public: true)
                       .tap { |t| t.line_items.create!(sku: sku, quantity: 1) }
  end

  let(:batch) do
    create(:warehouse_batch, user: user, warehouse_template: template, billing_profile: profile).tap do |b|
      3.times do |i|
        b.addresses.create!(first_name: "Person", last_name: i.to_s, line_1: "#{i} Main St",
                            city: "Burlington", state: "VT", postal_code: "05401", country: "US",
                            email: "person#{i}@example.com")
      end
      b.mark_fields_mapped!
    end
  end

  before { fake_hcb! }

  describe "#process!" do
    # Every dispatch! POSTs to Zenventory; `fail_on` makes the nth one blow up
    # the way a real outage would — after the earlier orders are already live.
    def stub_zenventory(fail_on: nil)
      calls = 0
      allow(Zenventory).to receive(:create_customer_order) do
        calls += 1
        raise Zenventory::ZenventoryError, "warehouse is on fire" if calls == fail_on
        { id: 1000 + calls }
      end
    end

    it "is re-runnable after a dispatch blows up partway through" do
      stub_zenventory(fail_on: 2)
      expect { batch.process! }.to raise_error(Zenventory::ZenventoryError)

      batch.reload
      expect(batch).to be_fields_mapped
      expect(batch.originated_orders.count).to eq(3)
      expect(batch.originated_orders.dispatched.count).to eq(1)

      stub_zenventory
      expect(batch.process!).to be_truthy

      batch.reload
      expect(batch).to be_processed
      expect(batch.originated_orders.count).to eq(3)
      expect(batch.originated_orders.map(&:aasm_state).uniq).to eq([ "dispatched" ])
      expect(batch.originated_orders.map(&:address_id)).to match_array(batch.addresses.ids)

      # One labor entry per order — no duplicates from the retry — and a single
      # transfer covering the lot.
      entries = LedgerEntry.labor.where(ledgerable: batch.originated_orders)
      expect(entries.count).to eq(3)
      expect(batch.originated_orders.map { |o| o.ledger_entries.labor.count }.uniq).to eq([ 1 ])
      expect(entries.map(&:state).uniq).to eq([ "settled" ])

      expect(HCB::Transfer.count).to eq(1)
      expect(HCB::Transfer.first.amount_cents).to eq(600)
      expect(hcb_disbursements.size).to eq(1)
    end

    it "does not rebuild orders or re-charge labor when run twice cleanly" do
      stub_zenventory
      expect(batch.process!).to be_truthy
      expect(batch.reload.originated_orders.count).to eq(3)

      batch.update!(aasm_state: "fields_mapped")
      expect(batch.process!).to be_truthy

      expect(batch.reload.originated_orders.count).to eq(3)
      expect(LedgerEntry.labor.count).to eq(3)
      expect(HCB::Transfer.count).to eq(1)
    end

    it "refuses the whole batch when a row can't be mailed" do
      stub_zenventory
      batch.addresses.first.update!(country: "RU") # warehouse won't ship there
      expect(batch.process!).to be(false)
      expect(batch.errors.full_messages.join).to match(/can't currently ship/i)
      expect(batch.reload.originated_orders.count).to eq(0)
    end
  end
end
