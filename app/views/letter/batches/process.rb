# frozen_string_literal: true

class Views::Letter::Batches::Process < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-container--narrow") do
      div(class: "page-header") do
        render Primer::Beta::Button.new(tag: :a, href: letter_batch_path(@batch), scheme: :invisible, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back to batch"
        end
        h1(class: "page-title") { "Process Letter Batch ##{@batch.id}" }
      end

      render Primer::Alpha::Banner.new(scheme: :default, mb: 4) do
        "This will generate labels for #{helpers.pluralize(@batch.addresses.count, 'address')}."
      end

      form_with(model: @batch, url: process_letter_batch_path(@batch), method: :post, scope: :batch) do |f|
        # Title
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h3) { "Letter Details" }
          end
          box.with_body do
            render Primer::Alpha::TextField.new(
              name: "batch[user_facing_title]",
              label: "Letter Title",
              caption: "Visible to recipients on their letters (e.g. \"Monthly Newsletter\")",
              full_width: true,
              mb: 3
            )

            # Mailing Date
            div(class: "form-field-lg") do
              label(class: "date-field-label", for: "batch_letter_mailing_date") { "Mailing Date" }
              p(class: "form-hint mb-2") { "Select the date you plan to mail these letters." }
              input(
                type: "date",
                name: "batch[letter_mailing_date]",
                id: "batch_letter_mailing_date",
                value: (@batch.letter_mailing_date || @batch.default_mailing_date).iso8601,
                min: Date.current.iso8601,
                required: true,
                class: "date-field w-full"
              )
            end
          end
        end

        # Templates
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h3) { "Label Templates" }
          end
          box.with_body do
            p(class: "form-hint mb-2") { "Select multiple templates to cycle through them, or just one for all labels." }
            template_select
          end
        end

        # QR Code
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h3) { "Options" }
          end
          box.with_body do
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

        # Postage
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h3) { "Postage" }
          end
          box.with_body do
            postage_options
            cost_info
          end
        end

        # Payment Account
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h3) { "Payment" }
          end
          box.with_body do
            payment_fields
          end
        end

        # Submit
        div(class: "page-actions") do
          render Primer::Beta::Button.new(tag: :a, href: letter_batch_path(@batch), scheme: :secondary) do
            "Cancel"
          end
          render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :play)
            "Generate Labels"
          end
        end
      end

      cost_update_script
    end
  end

  private

  def template_select
    standard_templates = SnailMail::PhlexService.templates_for_size(:standard)
    envelope_templates = SnailMail::PhlexService.templates_for_size(:envelope)

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

  def postage_options
    div(class: "postage-grid") do
      div do
        h4(class: "section-heading") { "US Mail" }
        div(class: "radio-group") do
          label(class: "form-check-label") do
            input(type: "radio", name: "batch[us_postage_type]", value: "stamps", checked: true)
            span { "Stamps" }
          end
          label(class: "form-check-label") do
            input(type: "radio", name: "batch[us_postage_type]", value: "indicia")
            span { "Indicia (Metered)" }
          end
        end
      end
      div do
        h4(class: "section-heading") { "International Mail" }
        div(class: "radio-group") do
          label(class: "form-check-label") do
            input(type: "radio", name: "batch[intl_postage_type]", value: "stamps", checked: true)
            span { "Stamps" }
          end
          label(class: "form-check-label") do
            input(type: "radio", name: "batch[intl_postage_type]", value: "indicia")
            span { "Indicia (Metered)" }
          end
        end
      end
    end
  end

  def cost_info
    div(id: "cost-info", class: "cost-info") do
      div(class: "cost-grid") do
        span(class: "kv-label") { "Total postage cost:" }
        span(id: "total_postage_cost", class: "fw-semibold") { number_to_currency(@batch.postage_cost) }

        span(class: "kv-label") { "US cost difference:" }
        span(id: "us_cost_difference") { number_to_currency(@batch.postage_cost_difference[:us]) }

        span(class: "kv-label") { "International cost difference:" }
        span(id: "intl_cost_difference") { number_to_currency(@batch.postage_cost_difference[:intl]) }
      end
      div(id: "cost_explanation", class: "form-hint mt-3") do
        us_count = @batch.letters.joins(:address).where(addresses: { country: "US" }).count
        intl_count = @batch.letters.joins(:address).where.not(addresses: { country: "US" }).count
        total_stamps = us_count + intl_count
        if total_stamps > 0
          plain "You'll have to put stamps on #{total_stamps} envelope#{"s" unless total_stamps == 1}"
        end
      end
    end
  end

  def payment_fields
    div(class: "form-field-lg") do
      label(class: "date-field-label", for: "batch_usps_payment_account_id") { "USPS Payment Account" }
      p(class: "form-hint mb-2") { "Required only when using indicia." }
      select(
        name: "batch[usps_payment_account_id]",
        id: "batch_usps_payment_account_id",
        class: "select-field"
      ) do
        option(value: "") { "Select a payment account..." }
        USPS::PaymentAccount.all.each do |pa|
          option(value: pa.id) { pa.display_name }
        end
      end
    end

    if current_user.hcb_payment_accounts.any?
      div do
        label(class: "date-field-label", for: "batch_hcb_payment_account_id") { "HCB Payment Account" }
        p(class: "form-hint mb-2") { "Required for indicia purchases." }
        select(
          name: "batch[hcb_payment_account_id]",
          id: "batch_hcb_payment_account_id",
          class: "select-field"
        ) do
          option(value: "") { "Select an HCB account..." }
          current_user.hcb_payment_accounts.each do |hcb|
            option(value: hcb.id) { hcb.display_name }
          end
        end
      end
    end
  end

  def cost_update_script
    script do
      raw <<~JS
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
