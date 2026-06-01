# frozen_string_literal: true

class Components::Batches::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(batch:)
    @batch = batch
  end

  def view_template
    if batch.errors.any?
      div(class: "error-box") do
        p(class: "error-box-title") do
          plain "#{batch.errors.count} error(s) prohibited this batch from being saved:"
        end
        ul(class: "error-box-list") do
          batch.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end

    form_with model: batch, local: true do |f|
      div(class: "form-stack") do
        # File input
        div do
          label(class: "date-field-label") do
            plain "CSV File"
            span(class: "text-danger") { "*" }
          end
          p(class: "section-desc mb-0") do
            plain "Upload a CSV file with addresses to process"
          end
          input(
            type: :file,
            name: "batch[csv]",
            accept: "text/csv",
            required: true,
            class: "file-input"
          )
        end

        div(class: "pt-2") do
          render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :upload)
            "Upload CSV"
          end
        end
      end
    end
  end

  private

  attr_reader :batch
end
