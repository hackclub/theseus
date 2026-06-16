# frozen_string_literal: true

class BatchProcessJob < ApplicationJob
  queue_as :default

  WORKERS = 5

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
      broadcast_summary(batch, phase: :purchasing, purchased: 0, total: total, failed: 0)
      purchase_indicia(batch, options)
    end

    # Phase 3: generate labels
    batch.mark_generating_labels! if batch.may_mark_generating_labels?
    broadcast_summary(batch, phase: :generating_labels)
    batch.generate_labels(options)

    batch.mark_processed! if batch.may_mark_processed?
    broadcast_summary(batch, phase: :done)
  end

  private

  def configure_letters(batch, options)
    batch.letters.find_each do |letter|
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
    hcb_account = HCB::PaymentAccount.find(options[:hcb_payment_account_id])

    letters_to_buy = batch.letters.includes(:address, :usps_indicium)
                          .where(postage_type: "indicia")
                          .where(indicia_state: [nil, "failed"])
                          .where.missing(:usps_indicium)
    total = letters_to_buy.count
    return if total == 0

    # Estimate cost and charge HCB
    estimated_cents = (letters_to_buy.sum(&:postage) * 100).ceil
    transfer = HCB::TransferService.new(
      hcb_payment_account: hcb_account,
      amount_cents: estimated_cents,
      name: "Postage for #{batch.public_id}",
      memo: "[theseus] batch postage",
    ).call
    raise "HCB transfer failed" unless transfer

    actual_cents = Concurrent::AtomicFixnum.new(0)
    purchased_count = Concurrent::AtomicFixnum.new(0)
    failed_count = Concurrent::AtomicFixnum.new(0)
    token_lock = Mutex.new
    payment_token = usps_account.create_payment_token

    pool = Concurrent::FixedThreadPool.new(WORKERS)

    letters_to_buy.find_each do |letter|
      pool.post do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            tok = token_lock.synchronize { payment_token }
            buy_indicium(letter, usps_account, hcb_account, batch, tok)
            letter.update_columns(indicia_state: "purchased")
            actual_cents.increment((letter.usps_indicium.cost * 100).ceil)
            purchased_count.increment
            broadcast_cell(batch, letter, "purchased")
          rescue Faraday::UnauthorizedError, USPS::USPSError => e
            # Token expired — refresh and retry once
            new_tok = token_lock.synchronize do
              payment_token = usps_account.create_payment_token
            end
            begin
              buy_indicium(letter, usps_account, hcb_account, batch, new_tok)
              letter.update_columns(indicia_state: "purchased")
              actual_cents.increment((letter.usps_indicium.cost * 100).ceil)
              purchased_count.increment
              broadcast_cell(batch, letter, "purchased")
            rescue => retry_err
              letter.update_columns(indicia_state: "failed", indicia_error: retry_err.message[0..500])
              failed_count.increment
              broadcast_cell(batch, letter, "failed")
              Sentry.capture_exception(retry_err, tags: { money: true }, extra: { letter_id: letter.id, batch_id: batch.id })
            end
          rescue => e
            letter.update_columns(indicia_state: "failed", indicia_error: e.message[0..500])
            failed_count.increment
            broadcast_cell(batch, letter, "failed")
            Sentry.capture_exception(e, tags: { money: true }, extra: { letter_id: letter.id, batch_id: batch.id })
          ensure
            broadcast_summary(batch, phase: :purchasing, purchased: purchased_count.value, total: total, failed: failed_count.value)
          end
        end
      end
    end

    pool.shutdown
    pool.wait_for_termination

    # Reconcile HCB — only refund if > $1
    overpaid = estimated_cents - actual_cents.value
    if overpaid > 100
      HCB::PaymentAccount.refund_to_organization!(
        organization_id: hcb_account.organization_id,
        amount_cents: overpaid,
        name: "Adjustment for #{batch.public_id}",
        memo: "[theseus] overpayment refund",
      )
    end

    batch.update!(hcb_payment_account: hcb_account, hcb_transfer_id: transfer.id)
  end

  def buy_indicium(letter, usps_account, hcb_account, batch, token)
    indicium = letter.usps_indicium || USPS::Indicium.create!(
      letter: letter,
      payment_account: usps_account,
      hcb_payment_account: hcb_account,
      mailing_date: batch.letter_mailing_date,
    )
    indicium.buy!(token) unless indicium.postage.present?
  end

  def broadcast_cell(batch, letter, state)
    icon = state == "purchased" ? "✓" : "✗"
    Turbo::StreamsChannel.broadcast_replace_to(
      batch, :progress,
      target: "cell-#{letter.id}",
      html: "<div id='cell-#{letter.id}' class='batch-cell batch-cell-#{state}' title='#{letter.public_id}: #{state}'>#{icon}</div>".html_safe
    )
  end

  def broadcast_summary(batch, **data)
    Turbo::StreamsChannel.broadcast_replace_to(
      batch, :progress,
      target: "batch-summary",
      partial: "letter/batches/grid_summary",
      locals: data.merge(batch: batch)
    )
  end
end
