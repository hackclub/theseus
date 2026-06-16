# frozen_string_literal: true

class Views::Letter::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: letter_batch_path(@batch), style: "text-decoration: none; color: GrayText;") { "← Batch ##{@batch.id}" }
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

          div(style: "display:flex;gap:0.5rem;margin-top:1rem;padding-top:1rem;border-top:1px solid var(--background2);") do
            button(type: "submit", class: "btn-success", data: { disable_with: "Processing…" }) { "▶ Start Processing" }
            a(href: letter_batch_path(@batch), style: "color:GrayText;align-self:center;") { "Cancel" }
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
    section(style: "margin-bottom: 1rem;") do
      strong { "Details" }
      hr

      div(style: "margin-top:0.75rem;") do
        label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "Batch Title" }
        input(
          type: "text",
          name: "batch[user_facing_title]",
          placeholder: "e.g. Monthly Newsletter, YSWS Stickers Round 3",
          style: "width:100%;",
          autofocus: true
        )
        p(class: "text-muted", style: "margin:0.25rem 0 0;font-size:0.85em;") { "Visible to recipients. Shows in the batch list." }
      end

      div(style: "margin-top:0.75rem;") do
        label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "Mailing Date" }
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

    section(style: "margin-bottom: 1rem;") do
      strong { "Label Templates" }
      hr
      div(style: "margin-top: 0.5rem;") do
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
    section(style: "margin-bottom: 1rem;") do
      strong { "Options" }
      hr
      div(style: "margin-top: 0.5rem;") do
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

    section(style: "margin-bottom: 1rem;") do
      strong { "Postage" }
      hr

      div(style: "display:flex;gap:2rem;margin-top:0.75rem;") do
        div do
          strong { "US Mail" }
          span(class: "text-muted", style: "margin-left:0.5rem;") { "(#{us_count} letters)" }
          div(style: "margin-top:0.25rem;display:flex;gap:1rem;") do
            label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
              input(type: "radio", name: "batch[us_postage_type]", value: "stamps", checked: true)
              plain " Stamps"
            end
            label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
              input(type: "radio", name: "batch[us_postage_type]", value: "indicia")
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
                input(type: "radio", name: "batch[intl_postage_type]", value: "stamps", checked: true)
                plain " Stamps"
              end
              label(style: "display:flex;align-items:center;gap:0.25rem;cursor:pointer;") do
                input(type: "radio", name: "batch[intl_postage_type]", value: "indicia")
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

    section(style: "margin-bottom: 1rem;") do
      strong { "Payment" }
      hr

      # USPS account — admin only, others get the default
      if current_user&.admin?
        admin_tool(element: "div") do
          div(style: "margin-top:0.75rem;") do
            label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "USPS Payment Account" }
            select(name: "batch[usps_payment_account_id]", style: "width:100%;") do
              USPS::PaymentAccount.all.each do |pa|
                option(value: pa.id, selected: pa.id == default_usps_id.to_i) { pa.display_name }
              end
            end
          end
        end
      else
        input(type: "hidden", name: "batch[usps_payment_account_id]", value: default_usps_id)
      end

      # HCB account
      if current_user.hcb_payment_accounts.any?
        div(style: "margin-top:0.75rem;") do
          label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") { "HCB Payment Account" }
          select(name: "batch[hcb_payment_account_id]", style: "width:100%;") do
            current_user.hcb_payment_accounts.each do |hcb|
              option(value: hcb.id) { hcb.display_name }
            end
          end
        end
      end
    end
  end

  def summary_card
    section do
      strong { "Batch Summary" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
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
      plain(<<~JS.html_safe)
        (function() {
          var postageInputs = document.querySelectorAll(
            'input[name="batch[us_postage_type]"], input[name="batch[intl_postage_type]"]'
          );
          var paymentSelect = document.getElementById('batch_usps_payment_account_id');
          var nonMachinableCheckbox = document.getElementById('batch_non_machinable');

          function updateCosts() {
            var usType = document.querySelector('input[name="batch[us_postage_type]"]:checked').value;
            var intlType = document.querySelector('input[name="batch[intl_postage_type]"]:checked').value;
            var nonMachinable = nonMachinableCheckbox ? nonMachinableCheckbox.checked : false;

            if (paymentSelect) {
              paymentSelect.required = (usType === 'indicia' || intlType === 'indicia');
            }

            fetch('#{update_costs_letter_batch_path(@batch)}', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
              },
              body: JSON.stringify({ us_postage_type: usType, intl_postage_type: intlType, non_machinable: nonMachinable })
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
              document.getElementById('total_postage_cost').textContent = '$' + data.total_cost.toFixed(2);
              document.getElementById('us_cost_difference').textContent = '$' + data.cost_difference.us.toFixed(2);
              document.getElementById('intl_cost_difference').textContent = '$' + data.cost_difference.intl.toFixed(2);
            });
          }

          postageInputs.forEach(function(input) {
            input.addEventListener('change', updateCosts);
          });
          if (nonMachinableCheckbox) nonMachinableCheckbox.addEventListener('change', updateCosts);
        })();
      JS
    end
  end
end
