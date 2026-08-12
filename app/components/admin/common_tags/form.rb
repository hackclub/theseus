# frozen_string_literal: true

class Components::Admin::CommonTags::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(common_tag:)
    @common_tag = common_tag
  end

  def view_template
    if @common_tag.errors.any?
      div(class: "banner banner-alert") do
        plain @common_tag.errors.full_messages.to_sentence
      end
    end

    form_with model: @common_tag, url: form_url, local: true do |f|
      div(class: "form-stack") do
        form_field("Tag", "common_tag[tag]", @common_tag.tag, required: true)

        div(style: "margin-bottom:1rem;") do
          label(style: "display:flex;align-items:center;gap:0.5rem;cursor:pointer;") do
            input(type: "hidden", name: "common_tag[implies_ysws]", value: "0")
            input(type: "checkbox", name: "common_tag[implies_ysws]", value: "1", checked: @common_tag.implies_ysws)
            plain "Implies YSWS"
          end
        end

        div(style: "padding-top:1rem;") do
          button(type: "submit", class: "btn-success") do
            plain(@common_tag.persisted? ? "Update Tag" : "Create Tag")
          end
        end
      end
    end
  end

  private

  def form_url
    @common_tag.persisted? ? admin_common_tag_path(@common_tag) : admin_common_tags_path
  end

  def form_field(label_text, name, value, required: false, type: "text")
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:GrayText;margin-bottom:0.25rem;") do
        plain label_text
        plain " *" if required
      end
      input(type: type, name: name, value: value, required: required, style: "width:100%;")
    end
  end
end
