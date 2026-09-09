# frozen_string_literal: true

class Views::Letter::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::NumberToCurrency
  register_element :turbo_frame, tag: "turbo-frame"

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(class: "flex-row") do
        a(href: letter_batch_path(@batch), style: "text-decoration: none; color: var(--foreground2);") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Process Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        form_with(model: @batch, url: process_letter_batch_path(@batch), method: :post, scope: :batch) do |f|
          letter_details_box(f)
          postage_box
          payment_box
          templates_box
          options_box

          div(id: "stamps-only-actions", style: "display:none;gap:0.5rem;margin-top:1rem;padding-top:1rem;border-top:1px solid var(--background2);") do
            button(type: "submit", class: "btn-success", data: { disable_with: "Processing…" }) { "▶ Start Processing" }
            a(href: letter_batch_path(@batch), style: "color:var(--foreground2);align-self:center;") { "Cancel" }
          end
        end

        cost_update_script
      end

      div(class: "show-sidebar") do
        summary_card
      end
    end
  end

  private

  def letter_details_box(f)
    section(class: "mb-1") do
      strong { "Details" }
      hr

      div(style: "margin-top:0.75rem;") do
        label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") { "Batch Title" }
        input(
          type: "text",
          name: "batch[user_facing_title]",
          placeholder: "e.g. Monthly Newsletter, YSWS Stickers Round 3",
          class: "w-100",
          autofocus: true
        )
        p(class: "text-muted", style: "margin:0.25rem 0 0;font-size:0.85em;") { "Visible to recipients. Shows in the batch list." }
      end

      div(style: "margin-top:0.75rem;") do
        label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") { "Mailing Date" }
        input(
          type: "date",
          name: "batch[letter_mailing_date]",
          value: (@batch.letter_mailing_date || @batch.default_mailing_date).iso8601,
          min: Date.current.iso8601,
          required: true
        )
      end
    end
  end

  def templates_box
    standard_templates = SnailMail::PhlexService.templates_for_size(:standard)
    envelope_templates = SnailMail::PhlexService.templates_for_size(:envelope)

    section(class: "mb-1") do
      strong { "Label Templates" }
      hr
      div(class: "mt-half") do
        p(class: "form-hint mb-2") { "Select multiple templates to cycle through them, or just one for all labels." }
        select(
          name: "batch[template_cycle]",
          id: "batch_template_cycle",
          multiple: true,
          size: [8, (standard_templates.length + envelope_templates.length + 2)].min,
          class: "multi-select-field"
        ) do
          if standard_templates.present?
            optgroup(label: "Standard 4x6 Labels") do
              standard_templates.uniq.each do |template|
                option(value: template.to_s) { template.to_s }
              end
            end
          end
          if envelope_templates.present?
            optgroup(label: "#10 Envelopes") do
              envelope_templates.uniq.each do |template|
                option(value: template.to_s) { template.to_s }
              end
            end
          end
        end
      end
    end
  end

  def options_box
    section(class: "mb-1") do
      strong { "Options" }
      hr
      div(class: "mt-half") do
        label(class: "form-check-label form-field") do
          input(type: "checkbox", name: "batch[include_qr_code]", value: "1", checked: true)
          span { "Include QR code on labels" }
        end
        div do
          label(class: "form-check-label") do
            input(type: "checkbox", name: "batch[non_machinable]", value: "1", id: "batch_non_machinable")
            span { "Non-machinable surcharge" }
          end
          p(class: "form-hint form-hint--indented") do
            plain "Check this if the mail pieces are rigid, square, or otherwise non-machinable (e.g. envelopes containing circuit boards, pins, or other bulky items)."
          end
        end
      end
    end
  end

  def postage_box
    us_count = @batch.letters.joins(:address).where(addresses: { country: "US" }).count
    intl_count = @batch.letters.count - us_count

    section(class: "mb-1") do
      strong { "Postage" }
      hr

      div(style: "display:flex;gap:2rem;margin-top:0.75rem;") do
        div do
          strong { "US Mail" }
          span(class: "text-muted", style: "margin-left:0.5rem;") { "(#{us_count} letters)" }
          div(style: "margin-top:0.25rem;display:flex;gap:1rem;") do
            label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
              input(type: "radio", name: "batch[us_postage_type]", value: "stamps", class: "postage-radio")
              plain " Stamps"
            end
            label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
              input(type: "radio", name: "batch[us_postage_type]", value: "indicia", checked: true, class: "postage-radio")
              plain " Indicia"
            end
          end
        end

        if intl_count > 0
          div do
            strong { "International" }
            span(class: "text-muted", style: "margin-left:0.5rem;") { "(#{intl_count} letters)" }
            div(style: "margin-top:0.25rem;display:flex;gap:1rem;") do
              label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
                input(type: "radio", name: "batch[intl_postage_type]", value: "stamps", class: "postage-radio")
                plain " Stamps"
              end
              label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
                input(type: "radio", name: "batch[intl_postage_type]", value: "indicia", checked: true, class: "postage-radio")
                plain " Indicia"
              end
            end
          end
        end
      end

      div(class: "detail-grid", style: "margin-top:0.75rem;") do
        span(class: "detail-label") { "Estimated cost" }
        strong(id: "total_postage_cost") { number_to_currency(@batch.postage_cost) }
      end
    end
  end

  def payment_box
    default_usps_id = ENV["DEFAULT_USPS_PACC_ID"] || USPS::PaymentAccount.first&.id

    section(id: "payment-section", class: "mb-1") do
      strong { "Payment" }
      hr

      # USPS account — admin only, others get the default
      if current_user&.admin?
        admin_tool(element: "div") do
          div(style: "margin-top:0.75rem;") do
            label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") { "USPS Payment Account" }
            select(name: "batch[usps_payment_account_id]", class: "w-100") do
              USPS::PaymentAccount.all.each do |pa|
                option(value: pa.id, selected: pa.id == default_usps_id.to_i) { pa.display_name }
              end
            end
          end
        end
      else
        input(type: "hidden", name: "batch[usps_payment_account_id]", value: default_usps_id)
      end

      turbo_frame(id: "billing-consent-frame") { consent }
    end
  end

  def consent
    render Components::MoneyNotice.new(
      lines: @batch.billing_lines(us_postage_type: "indicia", intl_postage_type: "indicia", non_machinable: false),
      profiles: current_user.billing_profiles,
      field: "batch[hcb_payment_account_id]",
      proceed: "Start Processing",
    )
  end

  def summary_card
    section do
      strong { "Batch Summary" }
      hr
      div(class: "detail-grid mt-half") do
        span(class: "detail-label") { "Addresses" }
        span { @batch.addresses.count.to_s }

        span(class: "detail-label") { "Letters" }
        span { @batch.letters.count.to_s }

        span(class: "detail-label") { "Dimensions" }
        span { "#{@batch.letter_width}\" × #{@batch.letter_height}\"" }

        span(class: "detail-label") { "Weight" }
        span { "#{@batch.letter_weight} oz" }

        span(class: "detail-label") { "Return Address" }
        span { @batch.letter_return_address&.display_name || "—" }
      end
    end
  end

  def cost_update_script
    script do
      raw(<<~JS.html_safe)
        (function() {
          var radios = document.querySelectorAll('.postage-radio');
          var paymentSection = document.getElementById('payment-section');
          var stampsActions = document.getElementById('stamps-only-actions');
          var frame = document.getElementById('billing-consent-frame');
          var nm = document.getElementById('batch_non_machinable');
          var consentUrl = '#{billing_consent_letter_batch_path(@batch)}';

          function needsIndicia() {
            var us = document.querySelector('input[name="batch[us_postage_type]"]:checked');
            var intl = document.querySelector('input[name="batch[intl_postage_type]"]:checked');
            return (us && us.value === 'indicia') || (intl && intl.value === 'indicia');
          }

          function toggle() {
            var indicia = needsIndicia();
            if (paymentSection) paymentSection.style.display = indicia ? '' : 'none';
            if (stampsActions) stampsActions.style.display = indicia ? 'none' : 'flex';
          }

          function refreshConsent() {
            if (!frame || !needsIndicia()) return;
            var us = document.querySelector('input[name="batch[us_postage_type]"]:checked');
            var intl = document.querySelector('input[name="batch[intl_postage_type]"]:checked');
            var sel = frame.querySelector('[data-money-select]');
            frame.src = consentUrl + '?' + new URLSearchParams({
              us_postage_type: us ? us.value : '',
              intl_postage_type: intl ? intl.value : '',
              non_machinable: nm && nm.checked ? '1' : '0',
              hcb_payment_account_id: sel ? sel.value : ''
            });
          }

          radios.forEach(function(r) { r.addEventListener('change', function() { toggle(); refreshConsent(); }); });
          if (nm) nm.addEventListener('change', refreshConsent);
          toggle();
        })();
      JS
    end
  end
end
