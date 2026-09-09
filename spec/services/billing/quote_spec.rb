# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Quote do
  let(:user) { create(:user) }
  let(:mailer_id) { create(:usps_mailer_id) }

  it "a letter bills its priced postage now" do
    letter = create(:letter, user: user, usps_mailer_id: mailer_id, postage_type: "indicia", batch: nil)
    quote = described_class.new(letter.billing_lines)
    expect(quote.now_cents).to eq((letter.postage * 100).ceil)
    expect(quote.lines.sole.label).to include(letter.public_id)
    expect(quote).not_to be_later
  end

  it "a warehouse order bills labor now and postage later, even before it's saved" do
    sku = create(:warehouse_sku, declared_unit_cost_override: 1.0)
    order = Warehouse::Order.new(user: user, recipient_email: "a@b.c", address: create(:address))
    order.line_items.build(sku: sku, quantity: 1)
    quote = described_class.new(order.billing_lines)
    expect(quote.now_cents).to eq(200)
    expect(quote.lines.last).to be_later.and have_attributes(category: :postage, known?: false)
  end

  it "prices a letter batch from the same pricer the letters use" do
    batch = create(:letter_batch, user: user, mailer_id: mailer_id, letter_mailing_date: 1.week.from_now.to_date)
    letter = create(:letter, user: user, batch: batch, usps_mailer_id: mailer_id, postage_type: "stamps", mailing_date: batch.letter_mailing_date)
    lines = batch.billing_lines(us_postage_type: "indicia", intl_postage_type: "indicia")
    expect(lines.sole.amount_cents).to eq((letter.postage_for(postage_type: "indicia") * 100).ceil)
    expect(batch.billing_lines(us_postage_type: "stamps", intl_postage_type: "stamps")).to be_empty
  end

  it "prices imported letters with no postage type yet as stamps and skips ones USPS won't quote" do
    batch = create(:letter_batch, user: user, mailer_id: mailer_id, letter_mailing_date: 1.week.from_now.to_date)
    letter = create(:letter, user: user, batch: batch, usps_mailer_id: mailer_id, postage_type: "stamps", mailing_date: batch.letter_mailing_date)
    letter.update_columns(postage_type: nil)
    expect(batch.postage_cost).to eq(letter.postage_for(postage_type: "stamps"))

    allow_any_instance_of(Letter).to receive(:postage_for).and_raise(USPS::USPSError.new("no rate"))
    expect(batch.postage_cost).to eq(0)
    expect(batch.billing_lines(us_postage_type: "indicia")).to be_empty
  end

  describe "#assess" do
    let(:quote) { described_class.new([ described_class::Line.new(category: :labor, when: :now, amount_cents: 500, count: 1), described_class::Line.new(category: :postage, when: :later, amount_cents: 1200, count: 1) ]) }

    it { expect(quote.assess(nil)).to eq(:unknown) }
    it { expect(quote.assess(400)).to eq(:insufficient) }
    it { expect(quote.assess(1000)).to eq(:low) }
    it { expect(quote.assess(1600)).to eq(:low) }
    it { expect(quote.assess(1800)).to eq(:ok) }
  end

  it "flags thin balances per order for batches" do
    quote = described_class.new([ described_class::Line.new(category: :labor, when: :now, amount_cents: 1000, count: 5) ])
    expect(quote.assess(5_999)).to eq(:low)
    expect(quote.assess(6_000)).to eq(:ok)
  end
end
