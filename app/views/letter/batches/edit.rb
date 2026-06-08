# frozen_string_literal: true

class Views::Letter::Batches::Edit < Views::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :available_tags
  register_output_helper :vite_javascript_tag

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    vite_javascript_tag("taggable")

    # Header
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: letter_batch_path(@batch), style: "text-decoration: none; color: var(--foreground2);") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Edit Letter Batch" }
      end
    end

    # Two-column layout
    div(class: "show-layout") do
      div(class: "show-main") do
        error_messages

        form_with(model: @batch, url: letter_batch_path(@batch), scope: :letter_batch, method: :patch) do |f|
          # Letter Specs
          div("box-": "round", style: "margin-bottom: 1lh;") do
            strong { "Letter Specs" }
            div("is-": "separator")
            div(style: "padding: 1lh 1ch;") do
              div(
                data_svelte_component: "letter-attributes-picker",
                data_form_scope: "letter_batch",
                data_is_batch: "true",
                data_initial_width: @batch.letter_width.to_s,
                data_initial_height: @batch.letter_height.to_s,
                data_initial_weight: (@batch.letter_weight || 1).to_s,
                data_initial_processing_category: (@batch.letter_processing_category || "letter").to_s
              )
            end
          end

          # Sender & Postage
          div("box-": "round", style: "margin-bottom: 1lh;") do
            strong { "Sender & Postage" }
            div("is-": "separator")
            div(style: "padding: 1lh 1ch;") do
              sender_fields(f)
            end
          end

          # Tags
          tag_picker(f)

          # Actions
          row("gap-": "1", style: "margin-top: 1lh;") do
            button(type: "submit", "variant-": "green") { "✓ Update Batch" }
            a(href: letter_batch_path(@batch)) { button("size-": "small") { "Cancel" } }
          end
        end
      end

      div(class: "show-sidebar") do
        batch_info_card
      end
    end
  end

  private

  def error_messages
    return unless @batch.errors.any?

    div("box-": "square", class: "tui-banner tui-banner-error", style: "margin-bottom: 1lh;") do
      strong { "[!] Hey, slight issue:" }
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
            option(value: m.id, selected: m.id == @batch.letter_mailer_id_id) { m.display_name }
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
            option(value: addr.id, selected: addr.id == @batch.letter_return_address_id) { addr.display_name }
          end
        end
      end
    end

    div(style: "margin-bottom: 1lh;") do
      label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25lh;") { "Custom Return Address Name" }
      input(type: "text", name: "letter_batch[letter_return_address_name]", value: @batch.letter_return_address_name, style: "width: 100%;")
      p(class: "form-hint") { "Leave blank to use the return address name" }
    end
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
          option(value: tag, selected: @batch.tags&.include?(tag)) { tag }
        end
      end
      p(class: "form-hint") { "Select from common tags or create your own" }
    end
  end

  def batch_info_card
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Batch Info" }
      div("is-": "separator")
      div(class: "detail-grid") do
        span(class: "detail-label") { "Letters" }
        span { @batch.letters.count.to_s }

        span(class: "detail-label") { "Addresses" }
        span { @batch.addresses.count.to_s }

        span(class: "detail-label") { "Status" }
        span { render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch) }
      end
    end
  end
end
