# frozen_string_literal: true

class Views::Letter::Batches::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::NumberToCurrency
  include Phlex::Rails::Helpers::TurboStreamFrom

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    if @batch.purchasing? || @batch.generating_labels?
      turbo_stream_from(@batch, :progress)
    end

    header_toolbar
    div(class: "show-layout") do
      div(class: "show-main") do
        details_box
        progress_section if show_progress?
        letters_table if @batch.letters.any?
        addresses_table if @batch.addresses.any?
      end
      div(class: "show-sidebar") do
        actions_box
        stats_box
      end
    end
  end

  private

  def show_progress?
    @batch.purchasing? || @batch.generating_labels? || @batch.processed?
  end

  def progress_section
    section(style: "margin-bottom: 1rem;") do
      strong { "Progress" }
      hr
      div(style: "margin-top: 0.5rem;") do
        if @batch.purchasing? || @batch.generating_labels?
          raw helpers.render(partial: "letter/batches/grid", locals: { cells: purchasing_grid_cells })
          raw helpers.render(partial: "letter/batches/grid_summary", locals: { batch: @batch })
        elsif @batch.processed?
          failed_letters = @batch.letters.where(indicia_state: "failed")
          if failed_letters.any?
            div(style: "margin-bottom: 0.5rem;") do
              span(class: "text-danger") { "#{failed_letters.count} letter(s) failed indicia purchase" }
            end
            raw helpers.render(partial: "letter/batches/grid", locals: { cells: purchasing_grid_cells })
            raw helpers.render(partial: "letter/batches/grid_summary", locals: { batch: @batch })
            div(style: "margin-top: 0.75rem; display: flex; gap: 0.5rem;") do
              form_with(url: retry_failed_letter_batch_path(@batch), method: :post, class: "form-inline") do
                button(type: "submit", class: "btn-warning btn-sm") { "⟳ Retry Failed" }
              end
              form_with(url: regenerate_labels_letter_batch_path(@batch), method: :post, class: "form-inline") do
                button(type: "submit", class: "btn-sm") { "⏩ Skip Failed & Regenerate Labels" }
              end
            end
          end
        end
      end
    end
  end

  def purchasing_grid_cells
    @batch.letters.select(:id, :public_id, :indicia_state).map do |letter|
      state = letter.indicia_state || "pending"
      icon = case state
             when "purchased" then "✓"
             when "failed" then "✗"
             else ""
             end
      { id: letter.id, state: state, title: letter.public_id, icon: icon }
    end
  end

  def header_toolbar
    div(class: "toolbar", style: "border-bottom: none; margin-bottom: 0;") do
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: letter_batches_path, style: "text-decoration: none; color: GrayText;") { "← Batches" }
        strong(style: "font-size: 1.15em;") { "Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      if @batch.tags.any?
        div(style: "display:flex;align-items:center;gap:0.5rem") do
          @batch.tags.compact_blank.each do |tag|
            span(class: "badge") { tag }
          end
        end
      end
      span(class: "spacer")
      div(style: "display:flex;align-items:center;gap:0.5rem") do
        a(href: edit_letter_batch_path(@batch)) { "✎ Edit" }
        if @batch.fields_mapped?
          a(href: process_confirm_letter_batch_path(@batch)) do
            button(class: "btn-success btn-sm") { "▶ Process" }
          end
        end
        form_with(url: letter_batch_path(@batch), method: :delete, data: { turbo_confirm: "Delete this batch?" }, class: "form-inline") do
          button(type: "submit", class: "btn-danger btn-sm") { "✕" }
        end
      end
    end
  end

  def details_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Details" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "Origin" }
        span { @batch.origin || "—" }

        span(class: "detail-label") { "Dimensions" }
        span { "#{@batch.letter_width}\" × #{@batch.letter_height}\", #{@batch.letter_weight} oz" }

        span(class: "detail-label") { "Mailer ID" }
        span { @batch.mailer_id&.display_name || "—" }

        span(class: "detail-label") { "Return Address" }
        span { @batch.letter_return_address&.display_name || "—" }

        span(class: "detail-label") { "Mailing Date" }
        span { @batch.letter_mailing_date&.strftime("%b %-d, %Y") || "—" }

        span(class: "detail-label") { "Created" }
        span { @batch.created_at.strftime("%b %-d, %Y %H:%M") }
      end
    end
  end

  def actions_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Actions" }
      hr
      div(style: "margin-top: 0.5rem;") do
        if @batch.processed?
          if @batch.pdf_label.attached?
            a(href: rails_blob_path(@batch.pdf_label, disposition: :inline), target: "_blank", style: "display: block; margin-bottom: 0.5rem;") do
              button(class: "btn-success", style: "width: 100%;") { "⬇ View Labels PDF" }
            end
          end

          form_with(url: mark_printed_letter_batch_path(@batch), method: :post) do
            button(type: "submit", style: "width: 100%; margin-bottom: 0.5rem;") { "✓ Mark All Printed" }
          end

          form_with(url: mark_mailed_letter_batch_path(@batch), method: :post) do
            button(type: "submit", style: "width: 100%; margin-bottom: 0.5rem;") { "✉ Mark All Mailed" }
          end

          a(href: regenerate_form_letter_batch_path(@batch), style: "display: block;") do
            button(class: "btn-sm", style: "width: 100%;") { "⟳ Regenerate Labels" }
          end
        elsif @batch.fields_mapped?
          a(href: process_confirm_letter_batch_path(@batch), style: "display: block;") do
            button(class: "btn-success", style: "width: 100%;") { "▶ Process Batch" }
          end
        elsif @batch.awaiting_field_mapping?
          a(href: map_fields_letter_batch_path(@batch), style: "display: block;") do
            button(class: "btn-success", style: "width: 100%;") { "⇉ Map Fields" }
          end
        end
      end
    end
  end

  def stats_box
    section(style: "margin-bottom: 1rem;") do
      strong { "Stats" }
      hr
      div(class: "detail-grid", style: "margin-top: 0.5rem;") do
        span(class: "detail-label") { "Letters" }
        span { helpers.number_with_delimiter(@batch.letters.count) }

        span(class: "detail-label") { "Addresses" }
        span { helpers.number_with_delimiter(@batch.addresses.count) }

        if @batch.processed?
          span(class: "detail-label") { "Total Postage" }
          span { number_to_currency(@batch.postage_cost) }
        end
      end
    end
  end

  def letters_table
    section(style: "margin-bottom: 1rem;") do
      strong { "Letters" }
      span(class: "text-muted", style: "margin-left: 0.5rem;") { "(#{@batch.letters.count})" }
      hr
      table do
        thead do
          tr do
            th { "ID" }
            th { "Recipient" }
            th { "Postage" }
            th { "Status" }
          end
        end
        tbody do
          @batch.letters.includes(:address).limit(100).each do |letter|
            tr do
              td do
                a(href: letter_path(letter), style: "text-decoration: none;") { letter.public_id }
              end
              td { plain [letter.address&.first_name, letter.address&.last_name].compact_blank.join(" ").presence || "—" }
              td(class: "text-muted") { plain letter.postage_type&.humanize || "—" }
              td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
            end
          end
        end
      end
      if @batch.letters.count > 100
        div(style: "padding: 0.5rem 0;", class: "text-muted") do
          plain "Showing first 100 of #{helpers.number_with_delimiter(@batch.letters.count)} letters"
        end
      end
    end
  end

  def addresses_table
    section(style: "margin-bottom: 1rem;") do
      strong { "Addresses" }
      span(class: "text-muted", style: "margin-left: 0.5rem;") { "(#{@batch.addresses.count})" }
      hr
      table do
        thead do
          tr do
            th { "Name" }
            th { "Address" }
            th { "City" }
            th { "State" }
            th { "ZIP" }
            th { "Country" }
          end
        end
        tbody do
          @batch.addresses.limit(100).each do |addr|
            tr do
              td { plain "#{addr.first_name} #{addr.last_name}" }
              td { plain "#{addr.line_1}#{addr.line_2.present? ? ", #{addr.line_2}" : ""}" }
              td { plain addr.city || "—" }
              td { plain addr.state || "—" }
              td { plain addr.postal_code || "—" }
              td { plain addr.country || "—" }
            end
          end
        end
      end
    end
  end
end
