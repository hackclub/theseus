# frozen_string_literal: true

class Views::Letter::Batches::Validate < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(batch:, validation:)
    @batch = batch
    @validation = validation
  end

  def view_template
    div(style: "display:flex;align-items:center;gap:0.5rem;margin-bottom:1rem;") do
      a(href: letter_batch_path(@batch), style: "text-decoration:none;color:GrayText;") { "← Batch ##{@batch.public_id}" }
      h2(style: "margin:0;") { "Batch #{@batch.public_id} — Validate CSV" }
    end

    valid_count = @validation.count { |r| r[:status] == :valid }
    error_count = @validation.count { |r| r[:status] == :error }
    total_count = @validation.size

    p(class: "batch-summary") do
      strong { "#{valid_count} valid" }
      plain ", "
      strong(style: error_count > 0 ? "color:var(--danger,red);" : nil) { "#{error_count} invalid" }
      plain " out of #{total_count} rows"
    end

    cells = @validation.map do |r|
      {
        id: "row-#{r[:row]}",
        state: r[:status] == :valid ? "valid" : "error",
        title: r[:errors].any? ? r[:errors].join("; ") : nil,
        icon: r[:status] == :valid ? "✓" : "✗",
        href: nil,
      }
    end

    raw helpers.render(partial: "letter/batches/grid", locals: { cells: cells })

    if error_count > 0
      h3 { "Invalid rows" }
      table(class: "table", style: "margin-top:0.5rem;") do
        thead do
          tr do
            th { "Row" }
            th { "Name" }
            th { "Errors" }
          end
        end
        tbody do
          @validation.select { |r| r[:status] == :error }.each do |r|
            tr do
              td { (r[:row] + 1).to_s }
              td { r[:sample] }
              td(style: "color:var(--danger,red);") { r[:errors].join(", ") }
            end
          end
        end
      end
    end

    div(style: "display:flex;gap:0.75rem;margin-top:1.5rem;") do
      if valid_count > 0
        button_to "Skip invalid & import (#{valid_count} rows)",
          import_with_skip_letter_batch_path(@batch),
          method: :post,
          class: "btn btn-primary"
      end

      if error_count == 0
        button_to "Import all",
          import_with_skip_letter_batch_path(@batch),
          method: :post,
          class: "btn btn-success"
      end

      a(href: new_letter_batch_path, class: "btn btn-secondary") { "Fix CSV & re-upload" }
    end
  end
end
