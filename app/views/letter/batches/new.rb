# frozen_string_literal: true

class Views::Letter::Batches::New < Views::Base
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
        a(href: letter_batches_path, class: "link-muted") { "← Batches" }
        strong(class: "text-title") { "New Letter Batch" }
      end
    end

render Components::Shared::ErrorMessages.new(record: @batch)

    form_with(model: @batch, url: letter_batches_path, scope: :letter_batch, multipart: true) do |f|
      section(class: "mb-1") do
        strong { "Letter Specs" }
        hr
        div(class: "mt-half") do
          div(
            data_svelte_component: "letter-attributes-picker",
            data_form_scope: "letter_batch",
            data_is_batch: "true",
            data_initial_weight: "1",
            data_initial_processing_category: "letter"
          )
        end
      end

      section(class: "mb-1") do
        strong { "Sender & Postage" }
        hr
        div(class: "mt-half") { sender_fields(f) }
      end

      section(class: "mb-1") do
        strong { "CSV File" }
        hr
        div(class: "mt-half") do
          input(type: "file", name: "letter_batch[csv]", accept: ".csv", required: true)
          p(class: "text-muted csv-hint") do
            plain "Upload a CSV with address columns. You'll map them on the next page."
          end
        end
      end

      tag_picker(f)

      div(class: "form-actions-row") do
        button(type: "submit", class: "btn-success") { "Upload & Map →" }
        a(href: letter_batches_path) { "Cancel" }
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
            option(value: m.id, selected: m.id == current_user.home_mid_id) { m.display_name }
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
            option(value: addr.id, selected: addr.id == current_user.home_return_address_id) { addr.display_name }
          end
        end
      end
      p(class: "form-hint") do
        a(href: return_addresses_path) { "Manage return addresses" }
      end
    end

    div(class: "mb-1") do
      label(class: "form-field-label") { "Custom Return Address Name" }
      input(type: "text", name: "letter_batch[letter_return_address_name]", class: "w-100")
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
          option(value: tag) { tag }
        end
      end
      p(class: "form-hint") { "Select from common tags or create your own" }
    end
  end
end
