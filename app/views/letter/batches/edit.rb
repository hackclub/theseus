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

    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: letter_batch_path(@batch), style: "text-decoration: none; color: var(--foreground2);") { "← Batch ##{@batch.id}" }
        strong(style: "font-size: 1.15em;") { "Edit Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        error_messages

        form_with(model: @batch, url: letter_batch_path(@batch), scope: :letter_batch, method: :patch) do |f|
          section(style: "margin-bottom: 1rem;") do
            strong { "Letter Specs" }
            hr
            div(style: "margin-top: 0.5rem;") do
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

          section(style: "margin-bottom: 1rem;") do
            strong { "Sender & Postage" }
            hr
            div(style: "margin-top: 0.5rem;") do
              sender_fields(f)
            end
          end

          tag_picker(f)

          div(style: "display:flex;gap:0.5rem;margin-top:1rem;") do
            button(type: "submit", class: "btn-success") { "✓ Update Batch" }
            a(href: letter_batch_path(@batch)) { button { "Cancel" } }
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

    section(style: "margin-bottom: 1rem; border-color: var(--red);") do
      strong(style: "color: var(--red);") { "#{@batch.errors.count} #{"error".pluralize(@batch.errors.count)} prevented saving" }
      hr
      ul(style: "margin: 0.5rem 0 0; padding-left: 1rem;") do
        @batch.errors.full_messages.each { |msg| li { msg } }
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

    div(style: "margin-bottom: 1rem;") do
      label(style: "display: block; color: var(--foreground2); margin-bottom: 0.25rem;") { "Custom Return Address Name" }
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
    section do
      strong { "Batch Info" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "Status" }
        span { render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch) }

        span(class: "detail-label") { "Letters" }
        span { @batch.letters.count.to_s }

        span(class: "detail-label") { "Addresses" }
        span { @batch.addresses.count.to_s }
      end
    end
  end
end
