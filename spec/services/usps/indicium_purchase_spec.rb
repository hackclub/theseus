# frozen_string_literal: true

require "rails_helper"

RSpec.describe USPS::IndiciumPurchase do
  let(:mailer_id) { create(:usps_mailer_id) }
  let(:user) { create(:user) }
  let(:profile) { create(:billing_profile, user: user) }
  let(:usps_account) { create(:usps_payment_account, usps_mailer_id: mailer_id) }
  let(:letter) { create(:letter, user: user, batch: nil, usps_mailer_id: mailer_id, postage_type: "indicia") }
  let(:estimate_cents) { (letter.postage * 100).ceil }

  before do
    fake_hcb!
    allow(usps_account).to receive(:create_payment_token).and_return("tok")
  end

  def stub_buy(&block)
    allow_any_instance_of(USPS::Indicium).to receive(:buy!) do |indicium, _token|
      block ? block.call(indicium) : indicium.update!(postage: 0.73, fees: 0.0, raw_json_response: { "indiciaMetadata" => {} })
    end
  end

  def purchase = described_class.new(letter: letter, usps_account: usps_account, billing_profile: profile).call

  it "charges the estimate, buys, and leaves a settled entry on the indicium" do
    stub_buy
    indicium = purchase
    expect(indicium.postage).to eq(0.73)
    entry = indicium.ledger_entries.sole
    expect(entry).to be_settled
    expect(entry.amount_cents).to eq(estimate_cents)
    expect(hcb_disbursements.sole[:to_organization_id]).to eq(Billing.destination_for(:indicia))
    expect(hcb_disbursements.sole[:name]).to include(letter.public_id)
  end

  it "refuses to buy twice" do
    stub_buy
    purchase
    expect { purchase }.to raise_error(described_class::AlreadyPurchased)
    expect(hcb_disbursements.size).to eq(1)
  end

  it "on a rejected charge, voids the entry, removes the indicium, and moves no money" do
    hcb_raises(api_error(HCBV4::UnprocessableEntityError, "not enough money", status: 422))
    expect { purchase }.to raise_error(Billing::Rejected)
    expect(letter.reload.usps_indicium).to be_nil
    expect(LedgerEntry.count).to eq(0)
    expect(HCB::Transfer.sole).to be_failed
  end

  it "on an unconfirmed charge, keeps everything and does not buy" do
    hcb_raises(Faraday::TimeoutError.new("boom"))
    expect_any_instance_of(USPS::Indicium).not_to receive(:buy!)
    expect { purchase }.to raise_error(Billing::Unconfirmed)
    expect(letter.reload.usps_indicium).to be_present
    expect(LedgerEntry.sole).to be_pending
    expect(HCB::Transfer.sole).to be_unknown

    # …and a retry while it's unconfirmed is refused, not re-charged
    expect { purchase }.to raise_error(Billing::Unconfirmed)
    expect(HCB::Transfer.count).to eq(1)
  end

  it "resumes an already-settled charge without charging again" do
    hcb_raises(Faraday::TimeoutError.new("boom"))
    expect { purchase }.to raise_error(Billing::Unconfirmed)
    HCB::Transfer.sole.complete!("xfr_found_later")

    fake_hcb!
    stub_buy
    purchase
    expect(hcb_disbursements).to be_empty
    expect(letter.reload.usps_indicium.postage).to eq(0.73)
  end

  it "credits the charge back when USPS provably sold nothing" do
    stub_buy { raise "USPS down" }
    expect { purchase }.to raise_error(described_class::PurchaseFailed) { |e| expect(e).to be_refunded }
    charge = LedgerEntry.charges.sole
    expect(charge.net_cents).to eq(0)
    expect(LedgerEntry.credits.sole).to be_settled
    expect(hcb_disbursements.map { |d| d[:direction] }).to eq(%i[debit credit])
  end

  it "does NOT refund when USPS already sold postage but saving failed" do
    stub_buy { |ind| ind.raw_json_response = { "indiciaImage" => "x" }; raise "save failed" }
    allow(Sentry).to receive(:capture_exception)
    expect { purchase }.to raise_error(described_class::Unrecorded)
    expect(LedgerEntry.credits).to be_empty
    expect(hcb_disbursements.size).to eq(1)
  end
end
