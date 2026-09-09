# frozen_string_literal: true

# One-time: turn the pre-ledger `hcb_transfer_id` columns on batches and
# usps_indicia into completed HCB::Transfer rows + settled ledger entries,
# so history and the new ledger add up to the same number.
#
# Amounts come from HCB where we can find the transfer on the HQ ledger
# (real), else from the postage estimate the charge was based on
# (estimate). metadata.amount_source says which.
#
#   Billing::Backfill.new.run!                # dry run: prints what it would do
#   Billing::Backfill.new(dry_run: false).run!
class Billing::Backfill
  attr_reader :dry_run, :log

  def initialize(dry_run: true, io: $stdout)
    @dry_run = dry_run
    @io = io
    @log = []
  end

  def run!
    remote = remote_transfers_by_id
    say "found #{remote.size} transfers on HQ's ledger"

    Batch.where.not(hcb_transfer_id: [nil, ""]).where.not(billing_profile: nil).find_each do |batch|
      next if batch.hcb_transfer_id.start_with?("mock")
      next if batch.ledger_entries.indicia.charges.exists?
      estimate = batch.letters.joins(:usps_indicium).sum("COALESCE(usps_indicia.postage,0) + COALESCE(usps_indicia.fees,0)")
      estimate = legacy_estimate(batch) if estimate.zero?
      backfill!(batch, batch.billing_profile, batch.hcb_transfer_id, remote, (estimate * 100).ceil, "Postage for #{batch.public_id}")
    end

    USPS::Indicium.where.not(hcb_transfer_id: [nil, ""]).where.not(billing_profile: nil).includes(:letter).find_each do |indicium|
      next if indicium.ledger_entries.indicia.charges.exists?
      estimate = ((indicium.letter&.postage || indicium.cost || 0) * 100).ceil
      backfill!(indicium, indicium.billing_profile, indicium.hcb_transfer_id, remote, estimate, "Postage for #{indicium.letter&.public_id || indicium.public_id}")
    end

    say "#{dry_run ? "would create" : "created"} #{log.size} entries (#{log.count { |l| l[:source] == "hcb" }} from HCB, #{log.count { |l| l[:source] == "estimate" }} estimated, #{log.count { |l| l[:source] == "skipped" }} skipped)"
    log
  end

  private

  # A main-era batch that died partway through purchase_batch_indicia kept its
  # hcb_transfer_id but rolled the indicia back, so there is nothing left to
  # price the charge from. Main charged the sum of the letters' own quoted
  # postage, which is still sitting on the letter rows; only fall back to a
  # live quote (which talks to USPS) if even that is gone.
  def legacy_estimate(batch)
    return 0 unless batch.respond_to?(:letters)

    stored = batch.letters.where(postage_type: "indicia").sum(:postage)
    return stored if stored.positive?

    batch.postage_cost
  rescue => e
    say "could not estimate #{batch.class}##{batch.id}: #{e.message}"
    0
  end

  def backfill!(ledgerable, profile, remote_id, remote, estimate_cents, name)
    found = remote[remote_id]
    amount_cents = found ? found.amount_cents.to_i.abs : estimate_cents
    source = found ? "hcb" : "estimate"
    if amount_cents <= 0
      log << { ledgerable: "#{ledgerable.class}##{ledgerable.id}", remote_id: remote_id, source: "skipped", reason: "no amount" }
      return say("skip #{ledgerable.class}##{ledgerable.id} (#{remote_id}): no amount available")
    end

    say "#{ledgerable.class}##{ledgerable.id} #{remote_id} $#{"%.2f" % (amount_cents / 100.0)} (#{source})"
    log << { ledgerable: "#{ledgerable.class}##{ledgerable.id}", remote_id: remote_id, amount_cents: amount_cents, source: source }
    return if dry_run

    ActiveRecord::Base.transaction do
      transfer = HCB::Transfer.create!(
        billing_profile: profile,
        direction: :debit,
        hq_organization_id: Billing.destination_for(:indicia),
        amount_cents: amount_cents,
        state: :completed,
        remote_id: remote_id,
        idempotency_key: "backfill_#{ledgerable.class.name.demodulize.downcase}_#{ledgerable.id}",
        name: name,
        attempts: 1,
        created_at: ledgerable.created_at,
        metadata: { "backfilled" => true, "amount_source" => source },
      )
      ledgerable.ledger_entries.create!(
        billing_profile: profile,
        category: :indicia,
        amount_cents: amount_cents,
        state: :settled,
        settled_at: ledgerable.created_at,
        hcb_transfer: transfer,
        created_at: ledgerable.created_at,
        metadata: { "backfilled" => true, "amount_source" => source },
      )
    end
  end

  def remote_transfers_by_id
    BillingProfile.theseus_client
      .transactions(Billing.destination_for(:indicia), limit: 100)
      .auto_paginate(max_pages: 500)
      .filter_map { |tx| tx.transfer }
      .index_by(&:id)
  rescue => e
    say "could not list HQ transactions (#{e.message}); falling back to estimates for everything"
    {}
  end

  def say(msg)
    @io.puts("[billing:backfill] #{msg}")
  end
end
