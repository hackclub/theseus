# frozen_string_literal: true

class Views::Letter::Batches::Show < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    div(class: "page-container") do
      render Components::Shared::PageHeader.new(
        title: "Letter Batch ##{@batch.id}",
        subtitle: "#{helpers.pluralize(@batch.addresses.count, 'address')} / #{helpers.pluralize(@batch.letters.count, 'letter')}"
      ) do |header|
        header.with_actions do
          a(href: letter_batches_path, style: "color: var(--foreground2);") { "← Back" }
          a(href: edit_letter_batch_path(@batch)) { button("size-": "small") { "✎ Edit" } }
          if @batch.fields_mapped?
            a(href: process_confirm_letter_batch_path(@batch)) do
              button("variant-": "green", "size-": "small") { "▶ Process" }
            end
          end
        end
      end

      batch_details
      batch_actions if @batch.processed?
      letters_section if @batch.letters.any?
      addresses_section if @batch.addresses.any?
      danger_zone
    end
  end

  private

  def batch_details
    div("box-": "round", style: "margin-bottom: 2lh;") do
      h3(style: "margin: 0; padding: 1lh 1ch 0;") { "Details" }
      div("is-": "separator")
      div(style: "padding: 1lh 1ch;") do
        dl(class: "detail-dl") do
          detail_row("Status") { render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch) }
          detail_row("Origin") { plain @batch.origin }
          detail_row("Letter Size") { plain "#{@batch.letter_width}\" x #{@batch.letter_height}\"" }
          detail_row("Weight") { plain "#{@batch.letter_weight} oz" }
          detail_row("Mailer ID") { plain @batch.mailer_id&.display_name || "—" }
          detail_row("Return Address") { plain @batch.letter_return_address&.display_name || "—" }
          detail_row("Mailing Date") { plain @batch.letter_mailing_date&.strftime("%b %-d, %Y") || "Not set" }
          detail_row("Created") { plain "#{time_ago_in_words(@batch.created_at)} ago" }

          if @batch.tags.any?
            detail_row("Tags") { render Components::Shared::Tags.new(tags: @batch.tags) }
          end
        end
      end
    end
  end

  def detail_row(label)
    dt { label }
    dd { yield }
  end

  def batch_actions
    div("box-": "round", style: "margin-bottom: 2lh;") do
      h3(style: "margin: 0; padding: 1lh 1ch 0;") { "Actions" }
      div("is-": "separator")
      div(style: "padding: 1lh 1ch;") do
        div(class: "page-actions") do
          if @batch.pdf_label.attached?
            a(href: rails_blob_path(@batch.pdf_label, disposition: :inline), target: "_blank") do
              button("variant-": "green") { "⬇ View Labels PDF" }
            end
          end

          form(method: :post, action: mark_printed_letter_batch_path(@batch), class: "form-inline") do
            input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
            button(type: "submit") { "✓ Mark All Printed" }
          end

          form(method: :post, action: mark_mailed_letter_batch_path(@batch), class: "form-inline") do
            input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
            button(type: "submit") { "◇ Mark All Mailed" }
          end

          a(href: regen_letter_batch_path(@batch)) do
            button("size-": "small") { "⟳ Regenerate Labels" }
          end
        end

        if @batch.processed?
          div(class: "text-sm mt-3 kv-label") do
            plain "Total postage: "
            strong { number_to_currency(@batch.postage_cost) }
          end
        end
      end
    end

  def letters_section
    details(class: "collapsible-section") do
      summary(class: "collapsible-summary") do
        "Letters (#{@batch.letters.count})"
      end
      div(class: "collapsible-body") do
        table(class: "data-table") do
          thead do
            tr do
              %w[ID Recipient Status Postage].each do |h|
                th { h }
              end
            end
          end
          tbody do
            @batch.letters.includes(:address).limit(100).each do |letter|
              tr do
                td do
                  a(href: letter_path(letter)) { letter.public_id }
                end
                td do
                  plain "#{letter.address&.first_name} #{letter.address&.last_name}"
                end
                td do
                  render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter)
                end
                td do
                  plain letter.postage_type || "—"
                end
              end
            end
          end
        end
        if @batch.letters.count > 100
          div(class: "data-table-footer") do
            "Showing first 100 of #{@batch.letters.count} letters"
          end
        end
      end
    end
  end

  def addresses_section
    details(class: "collapsible-section") do
      summary(class: "collapsible-summary") do
        "Addresses (#{@batch.addresses.count})"
      end
      div(class: "collapsible-body") do
        table(class: "data-table") do
          thead do
            tr do
              %w[Name Address City State ZIP Country].each do |h|
                th { h }
              end
            end
          end
          tbody do
            @batch.addresses.limit(100).each do |addr|
              tr do
                td { "#{addr.first_name} #{addr.last_name}" }
                td { "#{addr.line_1}#{addr.line_2.present? ? ", #{addr.line_2}" : ""}" }
                td { addr.city || "—" }
                td { addr.state || "—" }
                td { addr.postal_code || "—" }
                td { addr.country || "—" }
              end
            end
          end
        end
      end
    end
  end

  def danger_zone
    div(class: "danger-zone") do
      h3 { "Danger Zone" }
      p(class: "kv-label") { "This action cannot be undone." }
      form(method: :post, action: letter_batch_path(@batch)) do
        input(type: :hidden, name: :_method, value: :delete)
        input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
        button(type: "submit", "variant-": "red") { "✕ Delete this batch" }
      end
    end
  end
  end
end
