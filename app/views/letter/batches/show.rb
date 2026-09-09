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
    section(class: "mb-1") do
      strong { "Progress" }
      hr
      div(class: "mt-half") do
        if @batch.purchasing? || @batch.generating_labels?
          raw helpers.render(partial: "letter/batches/grid", locals: { cells: purchasing_grid_cells })
          raw helpers.render(partial: "letter/batches/grid_summary", locals: { batch: @batch })
        elsif @batch.processed?
          failed_letters = @batch.letters.where(indicia_state: "failed")
          if failed_letters.any?
            div(class: "mb-half") do
              span(class: "text-danger") { "#{failed_letters.count} letter(s) failed indicia purchase" }
            end
            raw helpers.render(partial: "letter/batches/grid", locals: { cells: purchasing_grid_cells })
            raw helpers.render(partial: "letter/batches/grid_summary", locals: { batch: @batch })
            div(class: "retry-actions-row") do
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
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: letter_batches_path, class: "link-muted") { "← Batches" }
        strong(class: "text-title") { "Batch ##{@batch.id}" }
        render Components::Shared::StatusBadge.new(status: @batch.aasm.current_state, type: :batch)
      end
      if @batch.tags.any?
        div(class: "flex-row") do
          @batch.tags.compact_blank.each do |tag|
            span(class: "badge") { tag }
          end
        end
      end
      span(class: "spacer")
      div(class: "flex-row") do
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
    section(class: "mb-1") do
      strong { "Details" }
      hr
      div(class: "detail-grid mt-half") do
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
    section(class: "mb-1") do
      if @batch.processed?
        printed = @batch.letters.where.not(printed_at: nil).count
        total = @batch.letters.count
        unprinted = total - printed

        # Print status
        div(class: "detail-grid mb-075") do
          span(class: "detail-label") { "Printed" }
          span { "#{printed} / #{total}" }
          if unprinted > 0
            span(class: "detail-label") { "Remaining" }
            strong { unprinted.to_s }
          end
        end

        # Print next N
        if unprinted > 0
          div(class: "print-subset-row") do
            [ 100, 500 ].each do |n|
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
          form_with(url: confirm_printed_letter_batch_path(@batch), method: :post, class: "form-inline mb-075") do
            button(type: "submit", class: "btn-sm") { "✓ Confirm last print" }
          end
        end

        hr

        # Secondary actions
        div(class: "secondary-actions-col") do
          if @batch.pdf_label.attached?
            a(href: rails_blob_path(@batch.pdf_label, disposition: :inline), target: "_blank", class: "link-reset") { "⬇ Full batch PDF" }
          end
          a(href: regenerate_form_letter_batch_path(@batch), class: "link-muted") { "⟳ Regenerate labels" }

          if printed > 0
            hr
            has_indicia = @batch.letters.where(postage_type: "indicia").where.not(indicia_state: nil).exists?
            if has_indicia
              reprint_warning
            else
              # Stamps only — reprint is harmless
              form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
                div(class: "action-row") do
                  input(type: "number", name: "count", value: "1", min: "1", max: @batch.letters.count.to_s, class: "w-4rem")
                  button(type: "submit", class: "btn-sm") { "🖨 Reprint" }
                end
              end
            end
          end

          hr
          form_with(url: mark_mailed_letter_batch_path(@batch), method: :post, class: "form-inline") do
            button(type: "submit", class: "btn-sm w-100") { "✉ Mark all mailed" }
          end
        end

      elsif @batch.fields_mapped?
        a(href: process_confirm_letter_batch_path(@batch), class: "btn-success btn-link-block") do
          plain "▶ Process Batch"
        end

      elsif @batch.awaiting_field_mapping?
        a(href: map_fields_letter_batch_path(@batch), class: "btn-success btn-link-block") do
          plain "⇉ Map Fields"
        end
      end
    end
  end

  def reprint_warning
    details(class: "my-quarter") do
      summary(class: "reprint-toggle") { "⚠ Reprint letters…" }
      div(class: "reprint-warning-box") do
        p(class: "reprint-warning-title") do
          plain "⚠ REPRINTING INDICIA LABELS CREATES DUPLICATE POSTAGE MARKS"
        end
        p(class: "reprint-warning-text") do
          plain "Each indicia label has a unique tracking number tied to paid postage. "
          plain "Printing the same label twice and mailing both copies is mail fraud "
          plain "under 18 U.S.C. § 1341. USPIS investigates duplicate indicia."
        end
        p(class: "reprint-warning-text") do
          strong { "Only reprint if the original was damaged, misprinted, or lost before mailing." }
        end
        form_with(url: print_subset_letter_batch_path(@batch), method: :post, class: "form-inline") do
          div(class: "action-row mt-half") do
            input(type: "number", name: "count", value: "1", min: "1", max: @batch.letters.count.to_s, class: "w-4rem")
            plain " letters from the start"
            button(type: "submit", class: "btn-sm btn-warning") { "Reprint" }
          end
        end
      end
    end
  end

  def stats_box
    section(class: "mb-1") do
      strong { "Stats" }
      hr
      div(class: "detail-grid mt-half") do
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

    section(class: "mb-1") do
      strong { "Letters" }
      span(class: "text-muted ml-half") { "(#{@batch.letters.count})" }
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
              td(class: "mono #{printed ? 'text-success' : 'text-unprinted'}") { printed ? "[✓]" : "[ ]" }
              td do
                a(href: letter_path(letter), class: "no-underline") { letter.public_id }
              end
              td { plain [ letter.address&.first_name, letter.address&.last_name ].compact_blank.join(" ").presence || "—" }
              td(class: "text-muted") { plain letter.postage_type&.humanize || "—" }
              td { render Components::Shared::StatusBadge.new(status: letter.aasm_state, type: :letter) }
            end
          end
        end
      end
      if @batch.letters.count > 100
        div(class: "text-muted py-half") do
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
      name = [ fname, lname ].compact_blank.join(" ")
      loc = [ city, state ].compact_blank.join(", ")
      state_class = printed_at ? "purchased" : "pending"
      state_class = "failed" if istate == "failed"
      { id: "pick-#{id}", letter_id: id, state: state_class, title: "#{name} — #{loc} (#{pub_id})" }
    end

    div("data-picklist-container": true, class: "mb-1h") do
      strong { "Select Letters" }
      span(class: "text-muted ml-half text-sm") { "click to select, shift-click for range" }

      div(class: "picklist-toolbar") do
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
      div("data-picklist-preview": true, class: "picklist-preview", style: "display:none;") do
      end

      div(class: "action-row mt-half") do
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
    section(class: "mb-1") do
      strong { "Addresses" }
      span(class: "text-muted ml-half") { "(#{@batch.addresses.count})" }
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
