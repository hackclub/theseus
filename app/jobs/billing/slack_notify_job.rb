# frozen_string_literal: true

# Needs BILLING_SLACK_WEBHOOK_URL; optional BILLING_SLACK_CHANNEL, BILLING_SLACK_MENTION.
class Billing::SlackNotifyJob < ApplicationJob
  queue_as :default

  def self.enabled? = ENV["BILLING_SLACK_WEBHOOK_URL"].present?

  def self.notify(transfer, kind)
    perform_later(transfer.id, kind) if enabled?
  end

  KINDS = {
    "nsf" => { emoji: ":rotating_light:", title: "INSUFFICIENT FUNDS" },
    "failed" => { emoji: ":x:", title: "Transfer failed" },
    "unknown" => { emoji: ":large_yellow_circle:", title: "Unconfirmed transfer" },
    "ambiguous" => { emoji: ":red_circle:", title: "Ambiguous reconciliation, needs a human" },
    "mismatch" => { emoji: ":skull:", title: "Ledger mismatch, refused to send" }
  }.freeze

  def perform(transfer_id, kind)
    webhook = ENV["BILLING_SLACK_WEBHOOK_URL"].presence
    return unless webhook

    transfer = HCB::Transfer.find(transfer_id)
    meta = KINDS.fetch(kind)

    Slack::Notifier.new(webhook) do
      defaults({ username: "theseus billing" }.merge(ENV["BILLING_SLACK_CHANNEL"].present? ? { channel: ENV["BILLING_SLACK_CHANNEL"] } : {}))
    end.ping(blocks: blocks(transfer, kind, meta))
  end

  private

  def blocks(transfer, kind, meta)
    profile = transfer.billing_profile
    mentions = [ ENV["BILLING_SLACK_MENTION"].presence ]
    mentions << "<@#{profile.user.slack_id}>" if kind == "nsf" && profile.user&.slack_id.present?
    mentions.compact!

    lines = transfer.ledger_entries.map { |e| "• #{e.category} #{Billing::Memo.ref(e.ledgerable)} #{Billing::Memo.money(e.amount_cents)} (T##{e.id})" }
    attempt = "attempt #{transfer.attempts}/#{HCB::Transfer::MAX_ATTEMPTS}"
    attempt += ", next at #{transfer.next_attempt_at.in_time_zone("America/New_York").strftime("%H:%M %Z")}" if transfer.next_attempt_at
    attempt += ", gave up" if transfer.gave_up?

    header = "#{meta[:emoji]} *#{meta[:title]}*: *#{profile.organization_name}* #{transfer.debit? ? "owes" : "is owed"} *#{Billing::Memo.money(transfer.amount_cents)}* (`#{transfer.idempotency_key}`)"
    header += " #{mentions.join(" ")}" if mentions.any?

    [
      { type: "section", text: { type: "mrkdwn", text: header } },
      { type: "context", elements: [ { type: "mrkdwn", text: "#{attempt} · linked by #{profile.user&.email} · #{transfer.last_error.presence || "no error"}" } ] },
      ({ type: "section", text: { type: "mrkdwn", text: lines.first(10).join("\n") } } if lines.any?),
      { type: "context", elements: [ { type: "mrkdwn", text: "<#{Rails.application.routes.url_helpers.billing_index_url(**Rails.application.config.action_mailer.default_url_options)}|open billing>" } ] }
    ].compact
  end
end
