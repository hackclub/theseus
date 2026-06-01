# frozen_string_literal: true

class Views::Letter::Batches::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :available_tags
  register_output_helper :vite_javascript_tag

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    vite_javascript_tag("taggable")

    div(class: "page-container") do
      div(class: "page-header") do
        render Primer::Beta::Button.new(tag: :a, href: letter_batches_path, scheme: :invisible, size: :small) do |btn|
          btn.with_leading_visual_icon(icon: :"arrow-left")
          "Back"
        end
        h1(class: "page-title") { "New Letter Batch" }
      end

      error_messages

      form_with(model: @batch, url: letter_batches_path, scope: :letter_batch) do |f|
        # Letter Specs
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h2) { "Letter Specs" }
          end
          box.with_body do
            div(
              data_svelte_component: "letter-attributes-picker",
              data_form_scope: "letter_batch",
              data_is_batch: "true",
              data_initial_weight: "1",
              data_initial_processing_category: "letter"
            )
          end
        end

        # Sender & Postage
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h2) { "Sender & Postage" }
          end
          box.with_body do
            sender_fields(f)
          end
        end

        # Addresses (CSV)
        render Primer::Beta::BorderBox.new(mb: 4) do |box|
          box.with_header do |header|
            header.with_title(tag: :h2) { "Addresses" }
          end
          box.with_body do
            address_fields = (Address.column_names - %w[id created_at updated_at batch_id]) + %w[rubber_stamps]
            div(
              data_svelte_component: "batch-csv-mapper",
              data_address_fields: address_fields.to_json,
              data_form_field_name: "letter_batch[addresses_data]"
            )
          end
        end

        # Tags
        tag_picker(f)

        # Actions
        div(class: "page-actions") do
          render Primer::Beta::Button.new(tag: :a, href: letter_batches_path, scheme: :secondary) do
            "Cancel"
          end
          render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :check)
            "Create Batch"
          end
        end
      end
    end
  end

  private

  def error_messages
    return unless @batch.errors.any?

    render Primer::Beta::Flash.new(scheme: :danger, mb: 3) do
      strong { "Hey, slight issue:" }
      ul(class: "error-list") do
        @batch.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def sender_fields(f)
    addresses = ReturnAddress.shared.or(ReturnAddress.owned_by(current_user))

    div(class: "form-field-lg") do
      label(class: "date-field-label", for: "letter_batch_letter_mailer_id_id") { "USPS Mailer ID" }
      div(class: "mt-1") do
        select(
          name: "letter_batch[letter_mailer_id_id]",
          id: "letter_batch_letter_mailer_id_id",
          class: "select-field"
        ) do
          USPS::MailerId.all.each do |m|
            option(
              value: m.id,
              selected: m.id == current_user.home_mid_id
            ) { m.display_name }
          end
        end
      end
    end

    div(class: "form-field-lg") do
      label(class: "date-field-label", for: "letter_batch_letter_return_address_id") { "Return Address" }
      div(class: "mt-1") do
        select(
          name: "letter_batch[letter_return_address_id]",
          id: "letter_batch_letter_return_address_id",
          class: "select-field"
        ) do
          addresses.each do |addr|
            option(
              value: addr.id,
              selected: addr.id == current_user.home_return_address_id
            ) { addr.display_name }
          end
        end
      end
      p(class: "form-hint") do
        a(href: return_addresses_path) { "Manage return addresses" }
      end
    end

    render Primer::Alpha::TextField.new(
      name: "letter_batch[letter_return_address_name]",
      label: "Custom Return Address Name",
      caption: "Leave blank to use the return address name",
      full_width: true,
      mb: 3
    )
  end

  def tag_picker(f)
    div(class: "form-field-lg") do
      label(class: "date-field-label") { "Tags" }
      select(
        name: "letter_batch[tags][]",
        multiple: true,
        class: "selectize-tags w-full"
      ) do
        available_tags.each do |tag|
          option(value: tag) { tag }
        end
      end
      p(class: "form-hint") { "Select from common tags or create your own" }
    end
  end
end
