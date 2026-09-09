# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Backfill do
  let(:mailer_id) { create(:usps_mailer_id) }
  let(:return_address) { create(:return_address) }
  let(:user) { create(:user, home_mid: mailer_id, home_return_address: return_address) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:usps_account) { create(:usps_payment_account, usps_mailer_id: mailer_id) }

  # A batch as main left it: charged HCB, transfer id on the batch row, ledger empty.
  let(:batch) do
    create(:letter_batch, user: user, mailer_id: mailer_id, letter_return_address: return_address).tap do |b|
      b.update_columns(hcb_transfer_id: "xfr_legacy", hcb_payment_account_id: profile.id)
    end
  end

  before do
    # No HQ ledger in specs; everything falls back to the estimate path.
    allow(BillingProfile).to receive(:theseus_client).and_raise("no network in specs")
  end

  def letter(postage:, bought: false)
    l = create(:letter, batch: batch, user: user, usps_mailer_id: mailer_id,
      return_address: return_address, address: create(:address), postage_type: "indicia")
    l.update_columns(postage: postage)
    if bought
      USPS::Indicium.create!(letter: l, payment_account: usps_account, billing_profile: profile,
        mailing_date: batch.letter_mailing_date, postage: postage, fees: 0.0)
    end
    l
  end

  def run! = described_class.new(dry_run: false, io: StringIO.new).run!

  it "prices a batch from its indicia when they survived" do
    letter(postage: 0.69, bought: true)
    letter(postage: 0.69, bought: true)

    run!

    expect(batch.ledger_entries.indicia.charges.sole.amount_cents).to eq(138)
  end

  # main's purchase_batch_indicia wrapped the indicia in a transaction, so a
  # half-failed batch has the transfer id and no indicia at all. Without a
  # fallback the entry is skipped as "no amount", the ledger stays empty, and
  # re-processing charges the whole batch a second time.
  it "falls back to the letters' quoted postage when the indicia were rolled back" do
    letter(postage: 0.69)
    letter(postage: 0.73)

    log = run!

    expect(log.sole).to include(source: "estimate", amount_cents: 142)
    entry = batch.ledger_entries.indicia.charges.sole
    expect(entry).to be_settled
    expect(entry.amount_cents).to eq(142)
    expect(entry.hcb_transfer.remote_id).to eq("xfr_legacy")
  end

  it "leaves a batch that already has a ledger entry alone" do
    letter(postage: 0.69, bought: true)
    run!
    expect { run! }.not_to change { batch.ledger_entries.count }
  end

  it "skips a batch with no way to price the charge" do
    batch # a legacy batch with no letters left to price from
    allow_any_instance_of(Letter::Batch).to receive(:postage_cost).and_return(0)

    log = run!

    expect(log.sole).to include(source: "skipped")
    expect(batch.ledger_entries).to be_empty
  end
end
