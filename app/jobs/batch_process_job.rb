# frozen_string_literal: true

class BatchProcessJob < ApplicationJob
  queue_as :default

  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "batch_process_#{arguments.first}" }
  )

  WORKERS = Rails.env.production? ? 5 : 1

  def perform(batch_id)
    batch = Letter::Batch.find(batch_id)
    return if batch.processed?
    options = (batch.process_options || {}).symbolize_keys

    # Phase 1: configure letters
    configure_letters(batch, options)

    # Phase 2: purchase indicia if needed
    if options[:us_postage_type] == "indicia" || options[:intl_postage_type] == "indicia"
      batch.mark_purchasing! if batch.may_mark_purchasing?
      total = batch.letters.where(postage_type: "indicia").count
      broadcast_summary(batch, purchased: 0, total: total, failed: 0)

      begin
        purchase_indicia(batch, options)
      rescue => e
        batch.update!(process_error: e.message)
        batch.mark_failed! if batch.may_mark_failed?
        broadcast_error_banner(batch, e.message)
        auto_refund_if_nothing_spent(batch, options)
        Sentry.capture_exception(e, tags: { money: true }, extra: { batch_id: batch.id })
        return
      end
    end

    # Phase 3: generate labels
    batch.mark_generating_labels! if batch.may_mark_generating_labels?
    begin
      batch.generate_labels(options)
    rescue => e
      batch.update!(process_error: "Label generation failed: #{e.message}")
      batch.mark_failed! if batch.may_mark_failed?
      broadcast_error_banner(batch, "Label generation failed: #{e.message}")
      Sentry.capture_exception(e, extra: { batch_id: batch.id })
      return
    end

    batch.update!(process_error: nil)
    batch.mark_processed! if batch.may_mark_processed?
    broadcast_done(batch)

  end
  private

  def configure_letters(batch, options)
    batch.letters.includes(:address).find_each do |letter|
      letter.mailing_date = batch.letter_mailing_date
      if letter.address&.us?
        letter.postage_type = options[:us_postage_type]
      else
        letter.postage_type = options[:intl_postage_type] || "international_origin"
      end
      letter.user_facing_title = options[:user_facing_title] if options[:user_facing_title].present?
      letter.non_machinable = options[:non_machinable] if options.key?(:non_machinable)
      letter.save!
    end
  end

  def purchase_indicia(batch, options)
    usps_account = USPS::PaymentAccount.find(options[:usps_payment_account_id])
    hcb_account = BillingProfile.find(options[:hcb_payment_account_id])

    letters_to_buy = batch.letters.includes(:address, :usps_indicium)
                          .where(postage_type: "indicia")
                          .where(indicia_state: [nil, "failed"])
    total = letters_to_buy.count
    return if total == 0

    estimated_cents = Billing::Quote.new(batch.billing_lines(letters: letters_to_buy)).now_cents
    charge_batch!(batch, hcb_account, estimated_cents)
    batch.update_columns(hcb_payment_account_id: hcb_account.id) if batch.hcb_payment_account_id != hcb_account.id

    actual_cents = Concurrent::AtomicFixnum.new(0)
    purchased_count = Concurrent::AtomicFixnum.new(0)
    failed_count = Concurrent::AtomicFixnum.new(0)
    token_lock = Mutex.new
    payment_token = usps_account.create_payment_token

    pool = Concurrent::FixedThreadPool.new(WORKERS)

    letters_to_buy.in_batches.each_record do |letter|
      pool.post do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            tok = token_lock.synchronize { payment_token }
            indicium = buy_indicium(letter, usps_account, hcb_account, batch, tok)
            letter.update_columns(indicia_state: "purchased")
            actual_cents.increment((indicium.cost * 100).ceil)
            purchased_count.increment
            broadcast_cell(batch, letter, "purchased")
          rescue Faraday::UnauthorizedError, Faraday::ForbiddenError => e
            # Token expired — refresh and retry once (double-check to avoid thundering herd)
            stale_tok = tok
            new_tok = token_lock.synchronize do
              if payment_token == stale_tok
                payment_token = usps_account.create_payment_token
              end
              payment_token
            end
            begin
              indicium = buy_indicium(letter, usps_account, hcb_account, batch, new_tok)
              letter.update_columns(indicia_state: "purchased")
              actual_cents.increment((indicium.cost * 100).ceil)
              purchased_count.increment
              broadcast_cell(batch, letter, "purchased")
            rescue => retry_err
              letter.update_columns(indicia_state: "failed", indicia_error: retry_err.message[0..500])
              failed_count.increment
              broadcast_cell(batch, letter, "failed")
              broadcast_letter_error(batch, letter, retry_err.message[0..200])
              Sentry.capture_exception(retry_err, tags: { money: true }, extra: { letter_id: letter.id, batch_id: batch.id })
            end
          rescue => e
            letter.update_columns(indicia_state: "failed", indicia_error: e.message[0..500])
            failed_count.increment
            broadcast_cell(batch, letter, "failed")
            broadcast_letter_error(batch, letter, e.message[0..200])
            Sentry.capture_exception(e, tags: { money: true }, extra: { letter_id: letter.id, batch_id: batch.id })
          ensure
            broadcast_summary(batch, purchased: purchased_count.value, total: total, failed: failed_count.value)
          end
        end
      end
    end

    pool.shutdown
    pool.wait_for_termination

    # overpayment refunds are manual via the refund_overpayment controller action.
  end

  # A batch is paid for by one organization. Re-runs (retrying failed
  # letters, or a batch that was auto-refunded) charge only what the money
  # already on hand doesn't cover, never more than was just consented to.
  def charge_batch!(batch, hcb_account, estimated_cents)
    raise Letter::Batch::LEGACY_CHARGE_NOT_BACKFILLED if batch.unbackfilled_legacy_charge?

    pending = batch.indicia_charges.pending.order(:id).last
    if pending
      raise "A previous HCB charge for this batch is still awaiting confirmation (#{pending.hcb_transfer&.idempotency_key}). Wait for it to resolve before retrying."
    end

    paid_by = batch.indicia_charges.settled.detect { |c| c.net_cents.positive? }&.billing_profile
    if paid_by && paid_by != hcb_account
      raise "#{batch.public_id} was already charged to #{paid_by.organization_name}; process it with that organization, or refund the overpayment first"
    end

    shortfall = estimated_cents - [ batch.prepaid_cents, 0 ].max
    unless shortfall.positive?
      Rails.logger.info("[BatchProcessJob] batch #{batch.id} has #{batch.prepaid_cents}c prepaid against #{estimated_cents}c of postage; not charging")
      return nil
    end

    unless Billing.mock?
      begin
        org = hcb_account.organization
        if org.balance_cents < shortfall
          raise "Insufficient HCB balance: #{org.name} has #{Billing::Memo.money(org.balance_cents)} but postage costs #{Billing::Memo.money(shortfall)}"
        end
      rescue => e
        raise if e.message.include?("Insufficient HCB balance")
        Sentry.capture_exception(e, level: :warning, extra: { batch_id: batch.id })
      end
    end

    entry = batch.ledger_entries.create!(
      billing_profile: hcb_account,
      category: :indicia,
      amount_cents: shortfall,
    )
    begin
      Billing.charge!([ entry ], name: "Postage for #{batch.public_id}", note: "batch postage", strict: true)
    rescue Billing::Rejected, Billing::InFlight => e
      entry.reload.void!(reason: e.message.truncate(200)) if entry.pending?
      raise "HCB transfer failed: #{e.message}"
    rescue Billing::Unconfirmed => e
      raise "HCB charge is awaiting confirmation (#{e.transfer.idempotency_key}); do not retry until it resolves"
    end
    entry.reload
  end

  # If the batch failed before a single indicium was bought, hand the whole
  # charge back. Anything else is a manual overpayment refund.
  def auto_refund_if_nothing_spent(batch, options)
    return if batch.letters.where(indicia_state: "purchased").exists?
    charge = batch.refundable_charge
    return unless charge

    Billing.credit!(
      reverses: charge,
      amount_cents: charge.net_cents,
      name: "Auto-refund for #{batch.public_id} (failed before purchasing)",
      note: "auto-refund, nothing was purchased",
    )
  rescue => e
    Sentry.capture_exception(e, tags: { money: true }, extra: { batch_id: batch.id })
  end

  def buy_indicium(letter, usps_account, hcb_account, batch, token)
    indicium = letter.usps_indicium || USPS::Indicium.create!(
      letter: letter,
      payment_account: usps_account,
      billing_profile: hcb_account,
      mailing_date: batch.letter_mailing_date,
    )
    indicium.buy!(token) unless indicium.postage.present?
    indicium.reload
  end

  def broadcast_cell(batch, letter, state)
    icon = state == "purchased" ? "✓" : "x"
    Turbo::StreamsChannel.broadcast_replace_to(
      [batch, :progress],
      target: "cell-#{letter.id}",
      html: "<span id=\"cell-#{letter.id}\" class=\"batch-cell batch-cell-#{state}\" title=\"#{letter.public_id}\">[#{icon}]</span>"
    )
  end

  def broadcast_letter_error(batch, letter, error)
    Turbo::StreamsChannel.broadcast_append_to(
      [batch, :progress],
      target: "batch-error-tbody",
      partial: "letter/batches/error_row",
      locals: { letter: letter, error_message: error }
    )
  end

  def broadcast_summary(batch, purchased:, total:, failed:)
    Turbo::StreamsChannel.broadcast_replace_to(
      [batch, :progress],
      target: "batch-summary",
      partial: "letter/batches/progress_summary",
      locals: { purchased: purchased, total: total, failed: failed }
    )
  end

  def broadcast_error_banner(batch, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      [batch, :progress],
      target: "batch-error-banner",
      html: "<div id=\"batch-error-banner\" class=\"banner banner-error\"><strong>Error:</strong> #{ERB::Util.html_escape(message)}</div>"
    )
  end

  def broadcast_done(batch)
    Turbo::StreamsChannel.broadcast_replace_to(
      [batch, :progress],
      target: "batch-actions",
      html: '<div id="batch-actions"><meta http-equiv="refresh" content="0"></div>'
    )
  end
end
