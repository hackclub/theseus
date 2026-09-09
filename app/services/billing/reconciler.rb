# frozen_string_literal: true

# Resolves transfers whose outcome we don't know by looking at what HCB
# actually did. Runs against the transfer's HQ organization (hq-usps-ops or
# hq-warehouse-ops) with the Theseus service token, so it doesn't depend on
# the user's OAuth being alive.
#
# Matching is by direction + counterparty org + amount, restricted to
# transactions dated on or after the transfer was created, excluding any
# HCB transfer id we already hold and any memo carrying a theseus key. With
# at most one in-flight transfer per profile (Billing::Charge enforces this)
# a single match is ours.
#
# This becomes belt-and-braces once HCB honours Idempotency-Key. See
# https://github.com/hackclub/theseus/issues/295
class Billing::Reconciler
  GRACE = 2.hours       # how long to keep looking before declaring "never happened"
  MAX_PAGES = 5
  KEY_PATTERN = /\[th_[A-Za-z0-9]+\]/

  Result = Struct.new(:transfer, :outcome, :detail)

  def self.run!
    HCB::Transfer.needs_reconciliation.find_each.map { |t| new(t).call }
  end

  attr_reader :transfer

  def initialize(transfer)
    @transfer = transfer
  end

  def call
    return Result.new(transfer, :skipped, "mock") if Billing.mock?
    return Result.new(transfer, :ambiguous, transfer.metadata["reconcile_ambiguous"]) if transfer.metadata["reconcile_ambiguous"].present?

    candidates = matching_remote_transfers
    case candidates.size
    when 1
      remote = candidates.first
      transfer.complete!(remote.id)
      transfer.update!(metadata: transfer.metadata.merge("reconciled_at" => Time.current.iso8601, "reconciled_by" => "match"))
      Billing::Executor.new(transfer).send(:write_memo, remote)
      Result.new(transfer, :completed, remote.id)
    when 0
      if transfer.created_at < GRACE.ago
        transfer.fail!("not found on HCB after #{GRACE.inspect}; safe to retry", retryable: true)
        transfer.update!(metadata: transfer.metadata.merge("reconciled_at" => Time.current.iso8601, "reconciled_by" => "absent"))
        Result.new(transfer, :failed, "absent")
      else
        Result.new(transfer, :waiting, "no match yet")
      end
    else
      transfer.update!(metadata: transfer.metadata.merge("reconcile_ambiguous" => candidates.map(&:id)))
      Billing::Alert.reconcile_ambiguous(transfer)
      Result.new(transfer, :ambiguous, candidates.map(&:id))
    end
  rescue => e
    Sentry.capture_exception(e, extra: { transfer_id: transfer.id }) if defined?(Sentry)
    Result.new(transfer, :error, e.message)
  end

  private

  def matching_remote_transfers
    known = HCB::Transfer.where.not(remote_id: nil).where.not(id: transfer.id).pluck(:remote_id).to_set
    org = transfer.billing_profile.organization_id
    since = (transfer.created_at - 1.day).to_date.iso8601

    list = BillingProfile.theseus_client.transactions(
      transfer.hq_organization_id,
      filters: { start_date: since },
      limit: 100,
    )

    list.auto_paginate(max_pages: MAX_PAGES).filter_map do |tx|
      remote = tx.transfer
      next unless remote
      next if known.include?(remote.id)
      next if tx.memo.to_s.match?(KEY_PATTERN) || remote.memo.to_s.match?(KEY_PATTERN)
      next unless remote.amount_cents.to_i.abs == transfer.amount_cents

      counterparty = transfer.debit? ? remote.from : remote.to
      next unless counterparty && [counterparty.id, counterparty.slug].include?(org)
      remote
    end.uniq(&:id)
  end
end
