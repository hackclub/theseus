# frozen_string_literal: true

class Views::Letter::Batches::Validate < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(batch:, validation:)
    @batch = batch
    @validation = validation
    @valid_count = validation.count { |r| r[:status] == :valid }
    @error_count = validation.count { |r| r[:status] == :error }
  end

  def view_template
    div(style: "display:flex;align-items:baseline;gap:0.5rem;margin-bottom:0.25rem;") do
      a(href: letter_batch_path(@batch), style: "text-decoration:none;color:GrayText;font-size:0.85em;") { "← #{@batch.public_id}" }
      h2(style: "margin:0;") { "Validate CSV" }
    end

    p(style: "margin:0 0 0.25rem;color:GrayText;") do
      strong(style: "color:inherit;") { @valid_count.to_s }
      plain " valid"
      if @error_count > 0
        plain " · "
        strong(style: "color:var(--red);") { @error_count.to_s }
        plain " invalid"
      end
      plain " of #{@validation.size} rows"
    end

    cells = @validation.map do |r|
      title = r[:status] == :error ? "Row #{r[:row] + 1}: #{r[:errors].join('; ')}" : nil
      { id: "row-#{r[:row]}", state: r[:status].to_s, title: title, icon: "", href: nil }
    end

    raw helpers.render(partial: "letter/batches/grid", locals: { cells: cells })

    if @error_count > 0
      div(style: "margin-top:1.25rem;") do
        strong(style: "font-size:0.85em;color:GrayText;text-transform:uppercase;letter-spacing:0.04em;") { "#{@error_count} invalid rows" }
        table(style: "margin-top:0.25rem;") do
          thead do
            tr do
              th(style: "width:4rem;") { "Row" }
              th { "Name" }
              th { "Issue" }
            end
          end
          tbody do
            @validation.select { |r| r[:status] == :error }.each do |r|
              tr do
                td(style: "font-variant-numeric:tabular-nums;") { (r[:row] + 1).to_s }
                td { r[:sample] }
                td(style: "color:var(--red);") { r[:errors].join(", ") }
              end
            end
          end
        end
      end
    end

    div(style: "display:flex;align-items:center;gap:0.75rem;margin-top:1.5rem;padding-top:1rem;border-top:1px solid var(--background2);") do
      if @valid_count > 0 && @error_count > 0
        button_to "Skip #{@error_count} invalid, import #{@valid_count} →",
          import_with_skip_letter_batch_path(@batch),
          method: :post,
          class: "btn-success"
      elsif @error_count == 0
        button_to "Import all #{@valid_count} rows →",
          import_with_skip_letter_batch_path(@batch),
          method: :post,
          class: "btn-success"
      end

      a(href: new_letter_batch_path, style: "color:GrayText;") { "Fix CSV & re-upload" }
    end
  end
end
