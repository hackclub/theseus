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

    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: letter_batch_path(@batch), class: "link-muted") { "← Batch ##{@batch.id}" }
        strong(class: "text-title") { "Edit Batch" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
render Components::Shared::ErrorMessages.new(record: @batch)

        form_with(model: @batch, url: letter_batch_path(@batch), scope: :letter_batch, method: :patch) do |f|
          section(class: "mb-1") do
            strong { "Always Editable" }
            hr
            div(class: "mt-half") do
              div(class: "form-field-lg") do
                label(class: "date-field-label", for: "letter_batch_user_facing_title") { "Title" }
                input(
                  type: "text",
                  name: "letter_batch[user_facing_title]",
                  id: "letter_batch_user_facing_title",
                  value: @batch.user_facing_title,
                  class: "w-100"
                )
                p(class: "form-hint") { "Visible to recipients. Shows in the batch list." }
              end

              tag_picker(f)
            end
          end

          if @batch.may_mark_processed?
            section(class: "mb-1") do
              strong { "Letter Specs" }
              hr
              div(class: "mt-half") do
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

            section(class: "mb-1") do
              strong { "Sender & Postage" }
              hr
              div(class: "mt-half") do
                sender_fields(f)
              end
            end
          end

          div(class: "form-actions-row") do
            button(type: "submit", class: "btn-success") { "✓ Update Batch" }
            a(href: letter_batch_path(@batch), class: "cancel-link") { "Cancel" }
          end
        end
      end

      div(class: "show-sidebar") do
        batch_info_card
      end
    end
  end

  private


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

    div(class: "mb-1") do
      label(class: "form-field-label") { "Custom Return Address Name" }
      input(type: "text", name: "letter_batch[letter_return_address_name]", value: @batch.letter_return_address_name, class: "w-100")
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
      div(class: "detail-grid mt-half") do
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
