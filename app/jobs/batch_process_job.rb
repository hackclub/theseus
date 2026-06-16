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
    hcb_account = HCB::PaymentAccount.find(options[:hcb_payment_account_id])

    letters_to_buy = batch.letters.includes(:address, :usps_indicium)
                          .where(postage_type: "indicia")
                          .where(indicia_state: [nil, "failed"])
    total = letters_to_buy.count
    return if total == 0

    estimated_cents = (letters_to_buy.sum(:postage) * 100).ceil
    transfer = if batch.hcb_transfer_id.present?
      batch.audit!(:hcb_charge_skipped, reason: "already charged", transfer_id: batch.hcb_transfer_id)
      nil
    elsif ENV["MOCK_HCB"].present?
      batch.update_columns(hcb_transfer_id: "mock_#{SecureRandom.hex(4)}", hcb_transfer_amount_cents: estimated_cents)
      batch.audit!(:hcb_charge_mocked, amount_cents: estimated_cents)
      nil
    else
      begin
        org = hcb_account.organization
        if org.balance_cents < estimated_cents
          raise "Insufficient HCB balance: #{org.name} has $#{'%.2f' % (org.balance_cents / 100.0)} " \
                "but postage costs $#{'%.2f' % (estimated_cents / 100.0)}"
        end
        batch.audit!(:hcb_balance_checked, balance_cents: org.balance_cents, estimated_cents: estimated_cents)
      rescue => e
        raise if e.message.include?("Insufficient HCB balance")
      end

      xfer = HCB::TransferService.new(
        hcb_payment_account: hcb_account,
        amount_cents: estimated_cents,
        name: "Postage for #{batch.public_id}",
        memo: "[theseus] batch postage",
      ).call
      raise "HCB transfer failed" unless xfer

      batch.update_columns(hcb_payment_account_id: hcb_account.id, hcb_transfer_id: xfer.id, hcb_transfer_amount_cents: estimated_cents)
      batch.audit!(:hcb_charged, amount_cents: estimated_cents, transfer_id: xfer.id)
      xfer
    end

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
          rescue Faraday::UnauthorizedError, USPS::USPSError => e
            # Token expired — refresh and retry once
            new_tok = token_lock.synchronize do
              payment_token = usps_account.create_payment_token
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

    # NOTE: reconciliation happens in perform after mark_processed,
    # NOT here. refunding inside purchase_indicia caused a money bug:
    # failed batch → full refund → retry skips charge → free postage.
  end

  def auto_refund_if_nothing_spent(batch, options)
    return unless batch.hcb_transfer_id.present?
    return if batch.hcb_transfer_id.start_with?("mock")
    return if batch.letters.where(indicia_state: "purchased").exists?

    amount = batch.hcb_transfer_amount_cents.to_i
    return if amount <= 0

    hcb_account = HCB::PaymentAccount.find_by(id: options[:hcb_payment_account_id])
    return unless hcb_account

    HCB::PaymentAccount.refund_to_organization!(
      organization_id: hcb_account.organization_id,
      amount_cents: amount,
      name: "Auto-refund for #{batch.public_id} (failed before purchasing)",
      memo: "[theseus] auto-refund, zero postage purchased",
    )
    batch.update_columns(hcb_transfer_id: nil, hcb_transfer_amount_cents: nil)
    batch.audit!(:hcb_auto_refunded, amount_cents: amount, reason: "failed before any postage purchased")
  rescue => e
    batch.audit!(:hcb_auto_refund_failed, error: e.message)
    Sentry.capture_exception(e, extra: { batch_id: batch.id })
  end


  def buy_indicium(letter, usps_account, hcb_account, batch, token)
    indicium = letter.usps_indicium || USPS::Indicium.create!(
      letter: letter,
      payment_account: usps_account,
      hcb_payment_account: hcb_account,
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
