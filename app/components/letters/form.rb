# frozen_string_literal: true

class Components::Letters::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :available_tags
  register_output_helper :vite_javascript_tag

  def initialize(letter:)
    @letter = letter
  end

  def view_template
    vite_javascript_tag("taggable")

    error_messages

    form_with(model: letter, url: form_url) do |f|
      # Letter Specs
      div("box-": "round", style: "margin-bottom: 2lh;") do
        h2(style: "margin: 0;") { "Letter Specs" }
        div("is-": "separator")
        div(
          data_svelte_component: "letter-attributes-picker",
          data_form_scope: "letter",
          data_is_batch: "false",
          data_initial_width: letter.width.to_s,
          data_initial_height: letter.height.to_s,
          data_initial_weight: (letter.weight || 1).to_s,
          data_initial_processing_category: (letter.processing_category || "letter").to_s,
          data_initial_non_machinable: (letter.non_machinable || false).to_s
        )

        mailing_date_field(f)
      end

      # Recipient Address
      div("box-": "round", style: "margin-bottom: 2lh;") do
        h2(style: "margin: 0;") { "Recipient Address" }
        div("is-": "separator")
        address_fields(f)
      end

      # Sender & Postage
      div("box-": "round", style: "margin-bottom: 2lh;") do
        h2(style: "margin: 0;") { "Sender & Postage" }
        div("is-": "separator")
        sender_postage_fields(f)
      end

      postage_script

      # Extras
      div("box-": "round", style: "margin-bottom: 2lh;") do
        h2(style: "margin: 0;") { "Extras" }
        div("is-": "separator")
        field_group(label: "Title", caption: "Optional — shown on the letter list") do
          input(
            type: "text",
            name: "letter[user_facing_title]",
            value: letter.user_facing_title,
            style: "width: 100%;"
          )
        end

        field_group(label: "Recipient email", caption: "Optional email address for the recipient") do
          input(
            type: "email",
            name: "letter[recipient_email]",
            value: letter.recipient_email,
            style: "width: 100%;"
          )
        end

        field_group(label: "Rubber stamps", caption: "Extra text to print on the label") do
          textarea(
            name: "letter[rubber_stamps]",
            rows: 3,
            style: "width: 100%;"
          ) { letter.rubber_stamps }
        end
      end

      # Tags
      tag_picker(f)

      # Actions
      div(class: "page-actions") do
        a(href: letters_path) { button { "Cancel" } }
        button(type: "submit", "variant-": "green") do
          plain letter.persisted? ? "✓ Update Letter" : "✓ Create Letter"
        end
      end
    end
  end

  private

  attr_reader :letter

  def field_group(label:, caption: nil, &block)
    div(style: "margin-bottom: 1lh;") do
      tag("label", style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { label }
      yield
      if caption
        span(style: "display: block; color: var(--foreground2); font-size: 0.85em; margin-top: 0.25lh;") { caption }
      end
    end
  end

  def form_url
    letter.persisted? ? letter_path(letter) : letters_path
  end

  def error_messages
    return unless letter.errors.any?

    div("box-": "square", class: "tui-banner tui-banner-error", style: "margin-bottom: 1lh;") do
      strong { "[!] Hey, slight issue:" }
      ul(class: "error-list") do
        letter.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def mailing_date_field(f)
    div(class: "form-field") do
      label(class: "date-field-label", for: "letter_mailing_date") { "Mailing date" }
      div(class: "mt-1") do
        input(
          type: "date",
          name: "letter[mailing_date]",
          id: "letter_mailing_date",
          value: (letter.mailing_date || letter.default_mailing_date)&.iso8601,
          min: letter.new_record? ? Date.current.iso8601 : nil,
          class: "date-field w-full"
        )
      end
      div(class: "quick-date-row") do
        button(
          type: "button",
          class: "quick-date-btn",
          data_mailing_date: Date.tomorrow.iso8601
        ) { "Tomorrow" }
        button(
          type: "button",
          class: "quick-date-btn",
          data_mailing_date: Date.current.next_occurring(:monday).iso8601
        ) { "Next Monday" }
      end
    end
  end

  def address_fields(f)
    countries = Address.countries_for_select.map do |code, name|
      flag = code.present? ? code.upcase.chars.map { |c| (c.ord + 127397).chr(Encoding::UTF_8) }.join : ""
      { code: code, name: name, flag: flag, display: "#{flag}  #{name}" }
    end

    top_codes = %w[US CA]
    top = top_codes.filter_map { |c| countries.find { |co| co[:code] == c } }
    others = countries.reject { |c| top_codes.include?(c[:code]) }
    all_ordered = top + others

    f.fields_for :address do |a|
      current_country = a.object&.country
      current_entry = countries.find { |c| c[:code] == current_country }
      form_id = "address-form-#{SecureRandom.hex(4)}"

      div(id: form_id, class: "address-form") do
        # Name
        div(class: "form-grid") do
          field_group(label: "First name") do
            input(
              type: "text",
              name: a.field_name(:first_name),
              value: a.object&.first_name,
              required: true,
              style: "width: 100%;"
            )
          end
          field_group(label: "Last name") do
            input(
              type: "text",
              name: a.field_name(:last_name),
              value: a.object&.last_name,
              style: "width: 100%;"
            )
          end
        end

        # Street
        field_group(label: "Street address") do
          input(
            type: "text",
            name: a.field_name(:line_1),
            value: a.object&.line_1,
            required: true,
            style: "width: 100%;"
          )
        end

        field_group(label: "Apt, suite, unit, etc.", caption: "Optional") do
          input(
            type: "text",
            name: a.field_name(:line_2),
            value: a.object&.line_2,
            style: "width: 100%;"
          )
        end

        # City / State / Postal
        div(class: "address-form-city-row") do
          field_group(label: "City") do
            input(
              type: "text",
              name: a.field_name(:city),
              value: a.object&.city,
              required: true,
              style: "width: 100%;"
            )
          end
          field_group(label: "State") do
            input(
              type: "text",
              name: a.field_name(:state),
              value: a.object&.state,
              required: true,
              style: "width: 100%;"
            )
          end
          field_group(label: "Postal code") do
            input(
              type: "text",
              name: a.field_name(:postal_code),
              value: a.object&.postal_code,
              required: true,
              style: "width: 100%;"
            )
          end
        end

        # Country
        div(class: "address-form-country") do
          field_group(label: "Country") do
            select(
              name: a.field_name(:country),
              id: "#{form_id}_country",
              style: "width: 100%;"
            ) do
              option(value: "") { "Select a country..." }
              all_ordered.each do |country|
                option(
                  value: country[:code],
                  selected: country[:code] == current_country
                ) { country[:display] }
              end
            end
          end
        end
      end

      country_filter_script(form_id)
    end
  end

  def country_filter_script(form_id)
    script do
      raw safe <<~JS
        (function() {
          var container = document.getElementById('#{form_id}');
          if (!container) return;
          var select = container.querySelector('select[id$="_country"]');
          if (!select) return;
          var filterInput = document.createElement('input');
          filterInput.type = 'text';
          filterInput.placeholder = 'Filter countries...';
          filterInput.style.cssText = 'width: 100%; margin-bottom: 0.5lh;';
          select.parentNode.insertBefore(filterInput, select);
          var options = Array.from(select.options);
          filterInput.addEventListener('input', function() {
            var q = filterInput.value.toLowerCase().trim();
            options.forEach(function(opt) {
              if (!opt.value) return;
              var text = opt.textContent.toLowerCase();
              var code = opt.value.toLowerCase();
              opt.style.display = (!q || code === q || text.indexOf(q) !== -1) ? '' : 'none';
            });
          });
        })();
      JS
    end
  end

  def sender_postage_fields(f)
    addresses = ReturnAddress.shared.or(ReturnAddress.owned_by(current_user))

    # Return address
    div(class: "form-field-lg") do
      label(class: "date-field-label", for: "letter_return_address_id") { "Return address" }
      div(class: "mt-1") do
        select(
          name: "letter[return_address_id]",
          id: "letter_return_address_id",
          class: "form-select"
        ) do
          option(value: "") { "Select a return address..." }
          addresses.each do |addr|
            option(
              value: addr.id,
              selected: addr.id == letter.return_address_id
            ) { addr.display_name }
          end
        end
      end
      p(class: "form-hint") do
        a(href: return_addresses_path(from_letter: true)) { "Manage return addresses" }
      end
    end

    field_group(label: "Custom return name", caption: "Leave blank to use the return address name") do
      input(
        type: "text",
        name: "letter[return_address_name]",
        value: letter.return_address_name,
        style: "width: 100%;"
      )
    end

    # Postage type (hidden by default, shown by JS for US addresses)
    div(id: "postage-options", class: "form-field-lg", style: "display: none;") do
      div do
        label(class: "date-field-label") { "Postage type" }
        div(class: "radio-row") do
          label(class: "radio-option") do
            input(
              type: "radio", name: "letter[postage_type]",
              value: "stamps",
              checked: letter.postage_type == "stamps" || letter.postage_type.blank?
            )
            plain " Stamps"
          end
          label(class: "radio-option") do
            input(
              type: "radio", name: "letter[postage_type]",
              value: "indicia",
              checked: letter.postage_type == "indicia"
            )
            plain " Indicia (Metered)"
          end
        end
        p(class: "form-hint") { "Indicia is slightly cheaper for standard letters" }
      end
    end

    # Mailer ID
    div(class: "form-field-lg") do
      label(class: "date-field-label", for: "letter_usps_mailer_id_id") { "USPS Mailer ID" }
      div(class: "mt-1") do
        select(
          name: "letter[usps_mailer_id_id]",
          id: "letter_usps_mailer_id_id",
          class: "form-select"
        ) do
          option(value: "") { "Select a mailer ID..." }
          USPS::MailerId.all.each do |m|
            option(
              value: m.id,
              selected: m.id == (letter.usps_mailer_id_id || USPS::MailerId.first&.id)
            ) { m.name }
          end
        end
      end
    end

    div("box-": "square", class: "tui-banner tui-banner-warning", style: "margin-top: 1lh;") do
      plain "[!] Please leave the mailer ID at the default if you're mailing from HQ — otherwise talk to Nora (it has USPS implications)."
    end
  end

  def postage_script
    addresses = ReturnAddress.shared.or(ReturnAddress.owned_by(current_user))
    address_data = addresses.map { |ra| { id: ra.id, country: ra.country } }

    script do
      raw <<~JS
        (function() {
          document.addEventListener('DOMContentLoaded', function() {
            var returnAddressSelect = document.getElementById('letter_return_address_id');
            var postageOptions = document.getElementById('postage-options');
            var stampsRadio = document.querySelector('input[name="letter[postage_type]"][value="stamps"]');
            var returnAddresses = #{address_data.to_json};

            function updatePostageOptions() {
              var selectedId = returnAddressSelect.value;
              if (!selectedId) {
                postageOptions.style.display = 'none';
                return;
              }

              var existingHidden = postageOptions.querySelector('input[type="hidden"][name="letter[postage_type]"]');
              if (existingHidden) existingHidden.remove();

              var selectedAddress = returnAddresses.find(function(ra) { return ra.id.toString() === selectedId; });
              var isUS = selectedAddress && selectedAddress.country === 'US';

              if (isUS) {
                postageOptions.style.display = 'block';
                if (!document.querySelector('input[name="letter[postage_type]"]:checked')) {
                  stampsRadio.checked = true;
                }
              } else {
                postageOptions.style.display = 'none';
                var internationalInput = document.createElement('input');
                internationalInput.type = 'hidden';
                internationalInput.name = 'letter[postage_type]';
                internationalInput.value = 'international_origin';
                postageOptions.appendChild(internationalInput);
              }
            }

            returnAddressSelect.addEventListener('change', updatePostageOptions);
            updatePostageOptions();

            document.querySelectorAll('[data-mailing-date]').forEach(function(btn) {
              btn.addEventListener('click', function() {
                document.getElementById('letter_mailing_date').value = btn.dataset.mailingDate;
              });
            });
          });
        })();
      JS
    end
  end

  def tag_picker(f)
    div(class: "form-field-lg") do
      label(class: "date-field-label") { "Tags" }
      select(
        name: "letter[tags][]",
        multiple: true,
        class: "selectize-tags w-full"
      ) do
        available_tags.each do |tag|
          option(value: tag, selected: letter.tags&.include?(tag)) { tag }
        end
      end
      p(class: "form-hint") { "Select from common tags or create your own" }
    end
  end
end
