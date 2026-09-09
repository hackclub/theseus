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
RSpec.describe Letter::Batch do
  let(:mailer_id) { create(:usps_mailer_id) }
  let(:return_address) { create(:return_address) }
  let(:user) { create(:user, home_mid: mailer_id, home_return_address: return_address) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:usps_account) { create(:usps_payment_account, usps_mailer_id: mailer_id) }
  let(:batch) { create(:letter_batch, user: user, mailer_id: mailer_id, letter_return_address: return_address) }

  # A letter as main left it: a real indicium with postage on it, and no
  # `indicia_state` (the column didn't exist yet).
  def legacy_letter(postage: 0.69, fees: 0.0, indicia_state: nil)
    letter = create(:letter, batch: batch, user: user, usps_mailer_id: mailer_id,
      return_address: return_address, address: create(:address), postage_type: "indicia")
    letter.update_columns(indicia_state: indicia_state)
    USPS::Indicium.create!(letter: letter, payment_account: usps_account, billing_profile: profile,
      mailing_date: batch.letter_mailing_date, postage: postage, fees: fees)
    letter
  end

  def settled_charge(cents)
    transfer = HCB::Transfer.create!(billing_profile: profile, direction: :debit,
      hq_organization_id: "org_hq", amount_cents: cents, state: :completed,
      idempotency_key: "spec_#{SecureRandom.hex(4)}", name: "Postage for #{batch.public_id}", attempts: 1)
    batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: cents,
      state: :settled, settled_at: Time.current, hcb_transfer: transfer)
  end

  describe "#actual_spent_cents" do
    it "counts indicia that have postage even when indicia_state was never set" do
      legacy_letter(postage: 0.69)
      legacy_letter(postage: 0.69)

      expect(batch.actual_spent_cents).to eq(138)
    end

    it "includes fees" do
      legacy_letter(postage: 0.69, fees: 0.31)

      expect(batch.actual_spent_cents).to eq(100)
    end

    it "ignores indicia rows that were created but never bought" do
      letter = create(:letter, batch: batch, user: user, usps_mailer_id: mailer_id,
        return_address: return_address, address: create(:address), postage_type: "indicia")
      USPS::Indicium.create!(letter: letter, payment_account: usps_account, billing_profile: profile,
        mailing_date: batch.letter_mailing_date)

      expect(batch.actual_spent_cents).to eq(0)
    end
  end

  describe "#propagate_to_letters!" do
    # This used to read `may_mark_processed?`, which meant "not processed"
    # only by accident of the transition list; adding `failed` to that list
    # would have changed who gets their sizing rewritten.
    def sized_letter
      create(:letter, batch: batch, user: user, usps_mailer_id: mailer_id,
        return_address: return_address, address: create(:address), weight: 1)
    end

    it "rewrites sizing on a batch that hasn't been processed, including a failed one" do
      letter = sized_letter
      batch.mark_fields_mapped!
      batch.mark_purchasing!
      batch.mark_failed!
      batch.update!(letter_weight: 2)

      batch.propagate_to_letters!

      expect(letter.reload.weight).to eq(2)
    end

    it "leaves a processed batch's letters alone" do
      letter = sized_letter
      batch.mark_fields_mapped!
      batch.mark_processed!
      batch.update!(letter_weight: 2)

      batch.propagate_to_letters!

      expect(letter.reload.weight).to eq(1)
    end
  end

  describe "#prepaid_cents" do
    # The phantom overpayment: billing:backfill records the main-era charge,
    # actual_spent_cents used to read 0 because indicia_state was nil, and the
    # processing page offered to refund the entire postage bill.
    it "is zero for a backfilled legacy batch whose letters have no indicia_state" do
      legacy_letter(postage: 0.69)
      legacy_letter(postage: 0.69)
      settled_charge(138)

      expect(batch.actual_spent_cents).to eq(138)
      # prepaid_cents is what the processing page offers to refund; the charge
      # itself still has net money on it, which is why the two must disagree.
      expect(batch.prepaid_cents).to eq(0)
      expect(batch.refundable_charge.net_cents).to eq(138)
    end

    it "still reports a real overpayment" do
      legacy_letter(postage: 0.69)
      settled_charge(200)

      expect(batch.prepaid_cents).to eq(131)
      expect(batch.refundable_charge).to be_present
    end
  end
end
