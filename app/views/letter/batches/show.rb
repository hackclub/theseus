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
        a(href: letter_batches_path, style: "text-decoration: none; color: var(--foreground2);") { "← Batches" }
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
      if @batch.processed?
        printed = @batch.letters.where.not(printed_at: nil).count
        total = @batch.letters.count
        unprinted = total - printed

        # Print status
        div(class: "detail-grid", style: "margin-bottom:0.75rem;") do
          span(class: "detail-label") { "Printed" }
          span { "#{printed} / #{total}" }
          if unprinted > 0
            span(class: "detail-label") { "Remaining" }
            strong { unprinted.to_s }
          end
        end

        # Print next N
        if unprinted > 0
          div(style: "display:flex;flex-wrap:wrap;gap:0.25rem;margin-bottom:0.75rem;") do
            [100, 500].each do |n|
              next if n > unprinted
              form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
                input(type: "hidden", name: "count", value: n)
                button(type: "submit", class: "btn-sm") { "🖨 Print #{n}" }
              end
            end
            form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
              input(type: "hidden", name: "count", value: unprinted)
              button(type: "submit", class: "btn-success btn-sm") { "🖨 Print all #{unprinted}" }
            end
          end

          # Confirm last print
          form_with(url: confirm_printed_letter_batch_path(@batch), method: :post, class: "form-inline", style: "margin-bottom:0.75rem;") do
            button(type: "submit", class: "btn-sm") { "✓ Confirm last print" }
          end
        end

        hr

        # Secondary actions
        div(style: "display:flex;flex-direction:column;gap:0.25rem;font-size:0.9em;") do
          if @batch.pdf_label.attached?
            a(href: rails_blob_path(@batch.pdf_label, disposition: :inline), target: "_blank", style: "text-decoration:none;color:inherit;") { "⬇ Full batch PDF" }
          end
          a(href: regenerate_form_letter_batch_path(@batch), style: "text-decoration:none;color:var(--foreground2);") { "⟳ Regenerate labels" }

          if printed > 0
            hr
            has_indicia = @batch.letters.where(postage_type: "indicia").where.not(indicia_state: nil).exists?
            if has_indicia
              reprint_warning
            else
              # Stamps only — reprint is harmless
              form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
                div(style: "display:flex;gap:0.5rem;align-items:center;") do
                  input(type: "number", name: "count", value: "1", min: "1", max: @batch.letters.count.to_s, style: "width:4rem;")
                  button(type: "submit", class: "btn-sm") { "🖨 Reprint" }
                end
              end
            end
          end

          hr
          form_with(url: mark_mailed_letter_batch_path(@batch), method: :post, class: "form-inline") do
            button(type: "submit", class: "btn-sm", style: "width:100%;") { "✉ Mark all mailed" }
          end
        end

      elsif @batch.fields_mapped?
        a(href: process_confirm_letter_batch_path(@batch), class: "btn-success", style: "display:block;text-align:center;text-decoration:none;") do
          plain "▶ Process Batch"
        end

      elsif @batch.awaiting_field_mapping?
        a(href: map_fields_letter_batch_path(@batch), class: "btn-success", style: "display:block;text-align:center;text-decoration:none;") do
          plain "⇉ Map Fields"
        end
      end
    end
  end

  def reprint_warning
    details(style: "margin:0.25rem 0;") do
      summary(style: "color:var(--yellow);font-size:0.85em;cursor:pointer;") { "⚠ Reprint letters…" }
      div(style: "margin-top:0.5rem;padding:0.75rem;background:var(--error-bg);border:1px solid var(--error-border);border-radius:4px;") do
        p(style: "margin:0 0 0.5rem;color:var(--error-fg);font-weight:600;") do
          plain "⚠ REPRINTING INDICIA LABELS CREATES DUPLICATE POSTAGE MARKS"
        end
        p(style: "margin:0 0 0.5rem;font-size:0.85em;color:var(--error-fg);") do
          plain "Each indicia label has a unique tracking number tied to paid postage. "
          plain "Printing the same label twice and mailing both copies is mail fraud "
          plain "under 18 U.S.C. § 1341. USPIS investigates duplicate indicia."
        end
        p(style: "margin:0 0 0.5rem;font-size:0.85em;color:var(--error-fg);") do
          strong { "Only reprint if the original was damaged, misprinted, or lost before mailing." }
        end
        form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
          div(style: "display:flex;gap:0.5rem;align-items:center;margin-top:0.5rem;") do
            input(type: "number", name: "count", value: "1", min: "1", max: @batch.letters.count.to_s, style: "width:4rem;")
            plain " letters from the start"
            button(type: "submit", class: "btn-sm btn-warning") { "Reprint" }
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


        if @batch.processed?
          span(class: "detail-label") { "Total Postage" }
          span { number_to_currency(@batch.postage_cost) }
        end
      end
    end
  end

  def letters_table
    if @batch.processed?
      picklist_section
    end

    section(style: "margin-bottom: 1rem;") do
      strong { "Letters" }
      span(class: "text-muted", style: "margin-left: 0.5rem;") { "(#{@batch.letters.count})" }
      hr
      table do
        thead do
          tr do
            th { "" }
            th { "ID" }
            th { "Recipient" }
            th { "Postage" }
            th { "Status" }
          end
        end
        tbody do
          @batch.letters.includes(:address).order(:id).limit(100).each do |letter|
            printed = letter.printed_at.present?
            tr do
              td(style: "font-family:monospace;color:#{printed ? 'var(--green)' : 'var(--background2)'};") { printed ? "[✓]" : "[ ]" }
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

  def picklist_section
    rows = @batch.letters.joins(:address).order("letters.id")
      .pluck("letters.id", "letters.public_id", "letters.printed_at", "letters.indicia_state",
             "addresses.first_name", "addresses.last_name", "addresses.city", "addresses.state")

    cells = rows.map do |id, pub_id, printed_at, istate, fname, lname, city, state|
      name = [fname, lname].compact_blank.join(" ")
      loc = [city, state].compact_blank.join(", ")
      state_class = printed_at ? "purchased" : "pending"
      state_class = "failed" if istate == "failed"
      { id: "pick-#{id}", letter_id: id, state: state_class, title: "#{name} — #{loc} (#{pub_id})" }
    end

    div("data-picklist-container": true, style: "margin-bottom:1.5rem;") do
      strong { "Select Letters" }
      span(class: "text-muted", style: "margin-left:0.5rem;font-size:0.85em;") { "click to select, shift-click for range" }

      div(style: "display:flex;gap:0.5rem;align-items:center;margin:0.5rem 0;font-size:0.85em;") do
        button(type: "button", class: "btn-sm", "data-select-all": true) { "All" }
        button(type: "button", class: "btn-sm", "data-select-none": true) { "None" }
        button(type: "button", class: "btn-sm", "data-select-unprinted": true) { "Unprinted" }
        button(type: "button", class: "btn-sm", "data-select-printed": true) { "Printed" }
        span(class: "spacer")
        strong("data-picklist-count": true) { "0" }
        span(class: "text-muted") { " selected" }
      end

      raw helpers.render(partial: "letter/batches/grid", locals: { cells: cells, picklist: true })

      # Selection preview — shows names of selected letters
      div("data-picklist-preview": true, style: "margin:0.5rem 0;font-size:0.85em;color:var(--foreground2);max-height:6rem;overflow-y:auto;font-family:monospace;display:none;") do
      end

      div(style: "display:flex;gap:0.5rem;align-items:center;margin-top:0.5rem;") do
        form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
          input(type: "hidden", name: "letter_ids", "data-picklist-ids": true)
          button(type: "submit", class: "btn-sm", "data-picklist-action": true, disabled: true) { "🖨 Print" }
        end
        form_with(url: confirm_printed_letter_batch_path(@batch), method: :post, class: "form-inline") do
          input(type: "hidden", name: "letter_ids", "data-picklist-ids": true)
          button(type: "submit", class: "btn-sm", "data-picklist-action": true, disabled: true) { "✓ Printed" }
        end
        form_with(url: mark_mailed_letter_batch_path(@batch), method: :post, class: "form-inline") do
          input(type: "hidden", name: "letter_ids", "data-picklist-ids": true)
          button(type: "submit", class: "btn-sm", "data-picklist-action": true, disabled: true) { "✉ Mailed" }
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
