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

    batch.update!(process_error: nil) # clear any previous error
    batch.mark_processed! if batch.may_mark_processed?
    broadcast_done(batch)

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

    # Charge HCB (idempotent — skip if already charged)
    estimated_cents = (letters_to_buy.sum(&:postage) * 100).ceil
    transfer = if batch.hcb_transfer_id.present?
      nil # already charged on a previous run
    elsif ENV["MOCK_HCB"].present?
      Rails.logger.info "[BatchProcessJob] MOCK_HCB: skipping HCB charge of #{estimated_cents} cents"
      batch.update!(hcb_transfer_id: "mock_#{SecureRandom.hex(4)}")
      nil
    else
      # Check balance before charging
      begin
        org = hcb_account.organization
        if org.balance_cents < estimated_cents
          raise "Insufficient HCB balance: #{org.name} has $#{'%.2f' % (org.balance_cents / 100.0)} " \
                "but postage costs $#{'%.2f' % (estimated_cents / 100.0)}"
        end
      rescue => e
        raise if e.message.include?("Insufficient HCB balance")
        Rails.logger.warn "[BatchProcessJob] Could not check HCB balance: #{e.message}"
        # proceed anyway — the transfer itself will fail if insufficient funds
      end

      xfer = HCB::TransferService.new(
        hcb_payment_account: hcb_account,
        amount_cents: estimated_cents,
        name: "Postage for #{batch.public_id}",
        memo: "[theseus] batch postage",
      ).call
      raise "HCB transfer failed: #{xfer.errors.join(', ') if xfer.respond_to?(:errors)}" unless xfer

      batch.update!(hcb_payment_account: hcb_account, hcb_transfer_id: xfer.id)
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

    # Reconcile HCB — refund overpayment if > $1
    if transfer
      overpaid = (transfer.respond_to?(:amount_cents) ? transfer.amount_cents : estimated_cents) - actual_cents.value
      if overpaid > 100
        HCB::PaymentAccount.refund_to_organization!(
          organization_id: hcb_account.organization_id,
          amount_cents: overpaid,
          name: "Adjustment for #{batch.public_id}",
          memo: "[theseus] overpayment refund",
        )
      end
    end
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
      html: "<tr id=\"error-#{letter.id}\"><td><a href=\"/back_office/letters/#{letter.public_id}\">#{letter.public_id}</a></td>" \
            "<td>#{ERB::Util.html_escape(letter.address&.first_name)} #{ERB::Util.html_escape(letter.address&.last_name)}</td>" \
            "<td style=\"color:var(--red)\">#{ERB::Util.html_escape(error)}</td></tr>"
    )
  end

  def broadcast_summary(batch, purchased:, total:, failed:)
    pct = total > 0 ? ((purchased + failed) * 100.0 / total).round(1) : 0
    remaining = total - purchased - failed
    html = <<~HTML
      <div id="batch-summary" style="display:flex;gap:1.5rem;align-items:center;margin-bottom:0.5rem;">
        <div><strong style="font-size:1.5em;font-variant-numeric:tabular-nums;">#{purchased}</strong>
        <span style="color:GrayText"> / #{total} purchased</span></div>
        #{failed > 0 ? "<div style=\"color:var(--red)\"><strong style=\"font-size:1.5em\">#{failed}</strong> failed</div>" : ""}
        #{remaining > 0 ? "<div style=\"color:GrayText\">#{remaining} remaining</div>" : ""}
      </div>
      <div class="batch-progress-bar" style="margin-bottom:0.75rem;">
        <div class="batch-progress-fill" style="width:#{pct}%"></div>
      </div>
    HTML
    Turbo::StreamsChannel.broadcast_replace_to(
      [batch, :progress],
      target: "batch-summary",
      html: html
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
    actions = "<div id=\"batch-actions\" style=\"display:flex;gap:0.75rem;align-items:center;margin-top:1rem;\">"
    if batch.pdf_label.attached?
      actions += "<a href=\"/back_office/letter/batches/#{batch.public_id}/regen\" class=\"btn-success\" style=\"text-decoration:none;\">⬇ Download Labels</a>"
    end
    failed_count = batch.letters.where(indicia_state: "failed").count
    if failed_count > 0
      actions += "<form method=\"post\" action=\"/back_office/letter/batches/#{batch.public_id}/retry_failed\" style=\"display:inline\">"
      actions += "<input type=\"hidden\" name=\"authenticity_token\" value=\"\">"
      actions += "<button class=\"btn-warning\">⟳ Retry #{failed_count} failed</button></form>"
    end
    actions += "<a href=\"/back_office/letter/batches/#{batch.public_id}\" style=\"color:GrayText\">← Back to batch</a></div>"
    Turbo::StreamsChannel.broadcast_replace_to(
      [batch, :progress],
      target: "batch-actions",
      html: actions
    )
  end
end
