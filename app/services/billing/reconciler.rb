# frozen_string_literal: true

# Resolves transfers whose outcome we don't know by looking at what HCB
# actually did. Runs against the transfer's HQ organization (hq-usps-ops or
# hq-warehouse-ops) with the Theseus service token, so it doesn't depend on
# the user's OAuth being alive.
#
# A memo carrying *this* transfer's key is a definite match and wins
# outright. Otherwise matching is by direction + counterparty org + amount,
# restricted to transactions dated on or after the transfer was created,
# excluding any HCB transfer id we already hold and any memo carrying a
# *different* theseus key. With at most one in-flight transfer per profile
# (Billing::Charge enforces this) a single match is ours.
#
# This becomes belt-and-braces once HCB honours Idempotency-Key. See
# https://github.com/hackclub/theseus/issues/295
class Billing::Reconciler
  GRACE = 2.hours       # how long to keep looking before declaring "never happened"
  MAX_PAGES = 5
  PAGE_SIZE = 100
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

    scan = scan_remote_transfers
    candidates = scan.candidates
    case candidates.size
    when 1
      remote = candidates.first
      transfer.complete!(remote.id)
      transfer.update!(metadata: transfer.metadata.merge("reconciled_at" => Time.current.iso8601, "reconciled_by" => "match"))
      Billing::Executor.new(transfer).send(:write_memo, remote)
      Result.new(transfer, :completed, remote.id)
    when 0
      if scan.truncated
        # We never saw the whole window, so "not there" means nothing.
        transfer.update!(metadata: transfer.metadata.merge("reconciled_at" => Time.current.iso8601, "reconciled_by" => "ceiling"))
        Result.new(transfer, :waiting, "listing truncated at #{MAX_PAGES} pages")
      elsif last_activity_at < GRACE.ago
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

  # The clock starts at the last time we actually talked to HCB, not at
  # creation. A transfer can sit in NSF backoff for hours and only go
  # `unknown` on a late attempt; measured from `created_at` the very next
  # reconcile run would call a transfer that HCB has not finished listing
  # "absent" and hand it back to the sweep to send again.
  def last_activity_at = [ transfer.last_attempted_at, transfer.created_at ].compact.max

  # `truncated` means we stopped at MAX_PAGES with pages still unread, so an
  # empty candidate list proves nothing. HCBV4::TransactionList#auto_paginate
  # swallows that fact (it just stops), so we drive #each_page ourselves and
  # ask the last page we read whether there was more behind it.
  Scan = Struct.new(:candidates, :truncated, keyword_init: true)

  def scan_remote_transfers
    known = HCB::Transfer.where.not(remote_id: nil).where.not(id: transfer.id).pluck(:remote_id).to_set
    org = transfer.billing_profile.organization_id
    since = (transfer.created_at - 1.day).to_date.iso8601

    list = BillingProfile.theseus_client.transactions(
      transfer.hq_organization_id,
      filters: { start_date: since },
      limit: PAGE_SIZE,
    )

    ours = "[#{transfer.idempotency_key}]"
    candidates = []
    truncated = false
    pages = 0

    catch(:definite) do
      list.each_page do |page|
        pages += 1
        page.each do |tx|
          remote = tx.transfer
          next unless remote
          next if known.include?(remote.id)

          memo = "#{tx.memo} #{remote.memo}"
          # Our own key in the memo is proof, not noise: Executor sends
          # `tagged_name` and HCB may reflect it into the memo. Nothing else
          # can outrank that, so stop looking.
          if memo.include?(ours)
            candidates = [ remote ]
            throw(:definite)
          end
          # Somebody else's key: that transfer is already accounted for.
          next if memo.match?(KEY_PATTERN)
          next unless remote.amount_cents.to_i.abs == transfer.amount_cents

          counterparty = transfer.debit? ? remote.from : remote.to
          next unless counterparty && [ counterparty.id, counterparty.slug ].include?(org)
          candidates << remote
        end

        if pages >= MAX_PAGES
          truncated = page.has_more?
          break
        end
      end
    end

    Scan.new(candidates: candidates.uniq(&:id), truncated: truncated)
  end
end
