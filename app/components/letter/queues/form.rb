# frozen_string_literal: true

class Components::Letter::Queues::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :available_tags
  register_output_helper :vite_javascript_tag

  def initialize(queue:)
    @queue = queue
  end

  def view_template
    vite_javascript_tag("taggable")

    error_messages

    form_with(model: queue, url: form_url, scope: :letter_queue) do |f|
      section_heading("The important part")

      div(class: "form-grid mb-3") do
        render Primer::Alpha::TextField.new(
          name: "letter_queue[name]", label: "Name",
          value: queue.name, required: true, full_width: true
        )
        render Primer::Alpha::TextField.new(
          name: "letter_queue[user_facing_title]", label: "Display Title",
          value: queue.user_facing_title, full_width: true,
          caption: "Optional title shown to users"
        )
      end

      tag_picker(f)

      section_heading("Letter defaults")

      # Template
      div(class: "form-field-lg") do
        render Components::Shared::TemplatePicker.new(
          form: f, name: :template,
          selected: queue.template, show_all: true
        )
      end

      # Letter dimensions (Svelte component)
      scope = "letter_queue"
      div(
        class: "form-field-lg",
        data_svelte_component: "letter-attributes-picker",
        data_form_scope: scope,
        data_is_batch: "true",
        data_initial_width: queue.letter_width.to_s,
        data_initial_height: queue.letter_height.to_s,
        data_initial_weight: (queue.letter_weight || 1).to_s,
        data_initial_processing_category: (queue.letter_processing_category || "letter").to_s
      )

      # Mailer ID
      select_field(
        name: "letter_queue[letter_mailer_id_id]",
        label: "USPS Mailer ID",
        options: USPS::MailerId.all.map { |m| [m.display_name, m.id] },
        selected: queue.letter_mailer_id_id || current_user.home_mid_id
      )

      # Return Address
      addresses = ReturnAddress.shared.or(ReturnAddress.owned_by(current_user))
      select_field(
        name: "letter_queue[letter_return_address_id]",
        label: "Return Address",
        options: addresses.map { |a| [a.display_name, a.id] },
        selected: queue.letter_return_address_id || current_user.home_return_address_id,
        link: { text: "(manage)", href: return_addresses_path }
      )

      div(class: "form-field-lg") do
        render Primer::Alpha::TextField.new(
          name: "letter_queue[letter_return_address_name]",
          label: "Custom return address name",
          value: queue.letter_return_address_name, full_width: true,
          caption: "Leave blank to use the address' default name"
        )
      end

      # Admin slug
      admin_tool do
        div(class: "form-field-lg") do
          render Primer::Alpha::TextField.new(
            name: "letter_queue[slug]", label: "Slug",
            value: queue.slug, full_width: true
          )
        end
      end

      # Submit
      div(class: "mt-4") do
        render Primer::Beta::Button.new(type: :submit, scheme: :primary) do |btn|
          btn.with_leading_visual_icon(icon: :check)
          queue.new_record? ? "Create Queue" : "Update Queue"
        end
      end
    end
  end

  private

  attr_reader :queue

  def form_url
    queue.new_record? ? letter_queues_path : letter_queue_path(queue)
  end

  def error_messages
    return unless queue.errors.any?

    div(class: "error-box") do
      strong { "#{queue.errors.count} #{"error".pluralize(queue.errors.count)} prohibited this queue from being saved:" }
      ul(class: "error-box-list") do
        queue.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def section_heading(text)
    h3(class: "form-section-heading") { text }
  end

  def tag_picker(f)
    div(class: "form-field-lg") do
      label(class: "date-field-label") { "Tags" }
      select(
        name: "letter_queue[tags][]",
        multiple: true,
        class: "selectize-tags w-full"
      ) do
        available_tags.each do |tag|
          option(value: tag, selected: queue.tags&.include?(tag)) { tag }
        end
      end
      p(class: "form-hint") { "Select from common tags or create your own" }
    end
  end

  def select_field(name:, label:, options:, selected: nil, link: nil)
    div(class: "form-field-lg") do
      div(class: "form-label-group") do
        label(class: "date-field-label") { label }
        if link
          a(href: link[:href], class: "text-sm") { link[:text] }
        end
      end
      select(name: name, class: "form-select--lg") do
        options.each do |display, value|
          option(value: value, selected: value.to_s == selected.to_s) { display }
        end
      end
    end
  end
end
