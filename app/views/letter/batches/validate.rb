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
    div(class: "form-label-group") do
      a(href: letter_batch_path(@batch), class: "link-muted text-sm") { "← #{@batch.public_id}" }
      h2(class: "m-0") { "Validate CSV" }
    end

    p(class: "validate-count-line") do
      strong(class: "color-inherit") { @valid_count.to_s }
      plain " valid"
      if @error_count > 0
        plain " · "
        strong(class: "text-danger") { @error_count.to_s }
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
      div(class: "validate-error-heading") do
        strong(class: "validate-error-label") { "#{@error_count} invalid rows" }
        table(class: "mt-quarter") do
          thead do
            tr do
              th(class: "w-4rem") { "Row" }
              th { "Name" }
              th { "Issue" }
            end
          end
          tbody do
            @validation.select { |r| r[:status] == :error }.each do |r|
              tr do
                td(class: "tabular") { (r[:row] + 1).to_s }
                td { r[:sample] }
                td(class: "text-danger") { r[:errors].join(", ") }
              end
            end
          end
        end
      end
    end

    div(class: "validate-actions-row") do
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

      a(href: new_letter_batch_path, class: "text-muted") { "Fix CSV & re-upload" }
    end
  end
end
