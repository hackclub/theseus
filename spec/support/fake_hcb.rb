# frozen_string_literal: true

# Stubs the two HCB seams Billing::Executor talks through, so specs never
# touch the network. Records every disbursement so tests can assert on
# exactly what would have been sent.
module FakeHCB
  RemoteTransfer = Struct.new(:id, :transaction_id, :amount_cents, :memo, :from, :to, keyword_init: true)
  RemoteOrg = Struct.new(:id, :slug, :name, keyword_init: true)

  def fake_hcb!
    @hcb_disbursements = []
    @hcb_memos = []
    counter = 0
    next_id = -> { counter += 1; "xfr_fake#{counter}" }

    allow_any_instance_of(BillingProfile).to receive(:create_disbursement!) do |profile, to_organization_id:, amount_cents:, name:|
      id = next_id.call
      @hcb_disbursements << { direction: :debit, profile: profile, to_organization_id: to_organization_id, amount_cents: amount_cents, name: name, id: id }
      RemoteTransfer.new(id: id, transaction_id: "txn_#{id}", amount_cents: amount_cents)
    end
    allow(BillingProfile).to receive(:refund_to_organization!) do |from_organization_id:, organization_id:, amount_cents:, name:|
      id = next_id.call
      @hcb_disbursements << { direction: :credit, from_organization_id: from_organization_id, organization_id: organization_id, amount_cents: amount_cents, name: name, id: id }
      RemoteTransfer.new(id: id, transaction_id: "txn_#{id}", amount_cents: amount_cents)
    end
    allow_any_instance_of(BillingProfile).to receive(:set_transaction_memo!) { |_p, tid, memo| @hcb_memos << [tid, memo] }
    allow(BillingProfile).to receive(:set_hq_transaction_memo!) { |_hq, tid, memo| @hcb_memos << [tid, memo] }
    allow_any_instance_of(BillingProfile).to receive(:organization).and_return(double(balance_cents: 10_000_000, name: "Test Org"))
  end

  attr_reader :hcb_disbursements, :hcb_memos

  def hcb_raises(error, direction: :debit)
    if direction == :debit
      allow_any_instance_of(BillingProfile).to receive(:create_disbursement!).and_raise(error)
    else
      allow(BillingProfile).to receive(:refund_to_organization!).and_raise(error)
    end
  end

  # Stub the mailer and return a spy you can assert on:
  #   mails = capture_billing_mail
  #   expect(mails).to have_received(:insufficient_funds)
  def capture_billing_mail
    mail = double("mail", deliver_later: true, deliver_now: true)
    spy = double("BillingMailer params")
    %i[transfer_failed insufficient_funds transfer_unknown reconcile_ambiguous].each { |m| allow(spy).to receive(m).and_return(mail) }
    allow(BillingMailer).to receive(:with).and_return(spy)
    spy
  end

  def api_error(klass, message, status:, error_code: nil)
    klass.new(message, status: status, error_code: error_code, messages: [message])
  end
end

RSpec.configure do |config|
  config.include FakeHCB
  config.include ActiveJob::TestHelper
end
