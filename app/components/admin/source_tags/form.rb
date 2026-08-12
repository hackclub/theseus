# frozen_string_literal: true

class Components::Admin::SourceTags::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(source_tag:)
    @source_tag = source_tag
  end

  def view_template
    if @source_tag.errors.any?
      div(class: "banner banner-alert") do
        plain @source_tag.errors.full_messages.to_sentence
      end
    end

    form_with model: @source_tag, url: form_url, local: true do |f|
      div(class: "form-stack") do
        form_field("Name", "source_tag[name]", @source_tag.name, required: true)
        form_field("Owner", "source_tag[owner]", @source_tag.owner)
        form_field("Slug", "source_tag[slug]", @source_tag.slug, required: true, hint: "URL-safe identifier, e.g. theseus_web")

        div(style: "padding-top:1rem;") do
          button(type: "submit", class: "btn-success") do
            plain(@source_tag.persisted? ? "Update Source Tag" : "Create Source Tag")
          end
        end
      end
    end
  end

  private

  def form_url
    @source_tag.persisted? ? admin_source_tag_path(@source_tag) : admin_source_tags_path
  end

  def form_field(label_text, name, value, required: false, type: "text", hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") do
        plain label_text
        plain " *" if required
      end
      input(type: type, name: name, value: value, required: required, style: "width:100%;")
      if hint
        small(class: "text-muted") { hint }
      end
    end
  end
end
