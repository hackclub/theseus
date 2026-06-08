# frozen_string_literal: true

class Views::Letter::Batches::Show < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::NumberToCurrency

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    # Header
    div(class: "page-toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      row("gap-": "1", "align-": "center") do
        a(href: letter_batches_path, style: "text-decoration: none; color: var(--foreground2);") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      row("gap-": "1", "align-": "center") do
        if @batch.tags.any?
          render Components::Shared::Tags.new(tags: @batch.tags)
        end
      end
      span(class: "toolbar-spacer")
      row("gap-": "1", "align-": "center") do
        a(href: edit_letter_batch_path(@batch)) { "✎ Edit" }
        if @batch.fields_mapped?
          a(href: process_confirm_letter_batch_path(@batch)) do
            button("variant-": "green", "size-": "small") { "▶ Process" }
          end
        end
        form(method: :post, action: letter_batch_path(@batch), style: "display: inline;") do
          input(type: :hidden, name: :_method, value: :delete)
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          button(type: "submit", "variant-": "red", "size-": "small") { "✕" }
        end
      end
    end

    # Two-column layout
    div(class: "show-layout") do
      div(class: "show-main") do
        batch_details
        letters_section if @batch.letters.any?
        addresses_section if @batch.addresses.any?
      end

      div(class: "show-sidebar") do
        actions_sidebar if @batch.processed?
        batch_stats
      end
    end
  end

  private

  def batch_details
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Details" }
      div("is-": "separator")
      div(class: "detail-grid") do
        span(class: "detail-label") { "Status" }
        span { render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch) }

        span(class: "detail-label") { "Origin" }
        span { @batch.origin }

        span(class: "detail-label") { "Dimensions" }
        span { "#{@batch.letter_width}\" × #{@batch.letter_height}\", #{@batch.letter_weight} oz" }

        span(class: "detail-label") { "Mailer ID" }
        span { @batch.mailer_id&.display_name || "—" }

        span(class: "detail-label") { "Return Address" }
        span { @batch.letter_return_address&.display_name || "—" }

        span(class: "detail-label") { "Mailing Date" }
        span { @batch.letter_mailing_date&.strftime("%b %-d, %Y") || "Not set" }

        span(class: "detail-label") { "Created" }
        span { "#{time_ago_in_words(@batch.created_at)} ago" }
      end
    end
  end

  def actions_sidebar
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Actions" }
      div("is-": "separator")
      column("gap-": "1") do
        if @batch.pdf_label.attached?
          a(href: rails_blob_path(@batch.pdf_label, disposition: :inline), target: "_blank", style: "width: 100%;") do
            button("variant-": "green", style: "width: 100%;") { "⬇ View Labels PDF" }
          end
        end

        form(method: :post, action: mark_printed_letter_batch_path(@batch)) do
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          button(type: "submit", style: "width: 100%;") { "✓ Mark All Printed" }
        end

        form(method: :post, action: mark_mailed_letter_batch_path(@batch)) do
          input(type: :hidden, name: :authenticity_token, value: form_authenticity_token)
          button(type: "submit", style: "width: 100%;") { "◇ Mark All Mailed" }
        end

        a(href: regen_letter_batch_path(@batch), style: "width: 100%;") do
          button("size-": "small", style: "width: 100%;") { "⟳ Regenerate Labels" }
        end
      end
    end
  end

  def batch_stats
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Stats" }
      div("is-": "separator")
      div(class: "detail-grid") do
        span(class: "detail-label") { "Letters" }
        span { @batch.letters.count.to_s }

        span(class: "detail-label") { "Addresses" }
        span { @batch.addresses.count.to_s }

        if @batch.processed?
          span(class: "detail-label") { "Total Postage" }
          span { number_to_currency(@batch.postage_cost) }
        end
      end
    end
  end

  def letters_section
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Letters (#{@batch.letters.count})" }
      div("is-": "separator")
      table(class: "data-table") do
        thead do
          tr do
            %w[ID Recipient Status Postage].each { |h| th { h } }
          end
        end
        tbody do
          @batch.letters.includes(:address).limit(100).each do |letter|
            tr do
              td { a(href: letter_path(letter)) { letter.public_id } }
              td { plain "#{letter.address&.first_name} #{letter.address&.last_name}" }
              td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
              td { plain letter.postage_type || "—" }
            end
          end
        end
      end
      if @batch.letters.count > 100
        div(style: "padding: 0.5lh 1ch; color: var(--foreground2);") do
          plain "Showing first 100 of #{@batch.letters.count} letters"
        end
      end
    end
  end

  def addresses_section
    div("box-": "round", style: "margin-bottom: 1lh;") do
      strong { "Addresses (#{@batch.addresses.count})" }
      div("is-": "separator")
      table(class: "data-table") do
        thead do
          tr do
            %w[Name Address City State ZIP Country].each { |h| th { h } }
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
