# frozen_string_literal: true

require "rails_helper"

# The "needing attention" table is the only place in Theseus that can move
# money a second time. HCB v4 has no idempotency, so the retry button for an
# `unknown` transfer has to warn and has to carry force=1.
RSpec.describe Views::Billing::Index do
  let(:user) { create(:user, is_admin: true) }
  let(:profile) { create(:billing_profile, user: user, organization_name: "Clubs") }
  let(:batch) { create(:letter_batch, user: user) }

  before { fake_hcb! }

  def transfer_in(state)
    entry = batch.ledger_entries.create!(billing_profile: profile, category: :indicia, amount_cents: 750)
    HCB::Transfer.create!(
      billing_profile: profile,
      direction: :debit,
      hq_organization_id: Billing.destination_for(:indicia),
      amount_cents: 750,
      name: "Postage",
      state: state,
      last_error: "boom",
      metadata: { "ledger_entry_ids" => [ entry.id ] },
    ).tap { |t| entry.update!(hcb_transfer: t, state: :pending) }
  end

  def render_index
    controller = BillingController.new
    controller.request = ActionDispatch::TestRequest.create
    allow(controller).to receive(:current_user).and_return(user)
    controller.view_context.render(described_class.new(ledger_entries: LedgerEntry.none.page(1), billing_profiles: []))
  end

  it "warns about the double charge and forces an unknown retry" do
    transfer_in(:unknown)
    html = render_index

    expect(html).to include("Force retry (may double charge)")
    expect(html).to include("data-turbo-confirm")
    expect(html).to include("may ALREADY have landed on HCB")
      .and include("charge Clubs $7.50 a second time")
    expect(html).to include(%(name="force" value="1"))
  end

  it "does not force or warn on a plain failed retry" do
    transfer_in(:failed)
    html = render_index

    expect(html).to include("Retry now")
    expect(html).not_to include("data-turbo-confirm")
    expect(html).not_to include(%(name="force"))
  end
end
