class Components::Admin::USPS::MailerIds::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(mailer_id:)
    @mailer_id = mailer_id
  end

  def view_template
    if @mailer_id.errors.any?
      div(class: "banner banner-alert") do
        plain @mailer_id.errors.full_messages.to_sentence
      end
    end

    form_with model: @mailer_id, url: form_url, local: true do |f|
      div(class: "form-stack") do
        form_field("Name", "usps_mailer_id[name]", @mailer_id.name, required: true, hint: "Human-readable label")
        form_field("CRID", "usps_mailer_id[crid]", @mailer_id.crid, required: true, hint: "USPS Customer Registration ID")
        form_field("MID", "usps_mailer_id[mid]", @mailer_id.mid, required: true, hint: "USPS Mailer Identifier")

        div(style: "padding-top:1rem;") do
          button(type: "submit", class: "btn-success") do
            plain(@mailer_id.persisted? ? "Update Mailer ID" : "Create Mailer ID")
          end
        end
      end
    end
  end

  private

  def form_url
    @mailer_id.persisted? ? admin_usps_mailer_id_path(@mailer_id) : admin_usps_mailer_ids_path
  end

  def form_field(label_text, name, value, required: false, type: "text", hint: nil)
    div(style: "margin-bottom:1rem;") do
      label(style: "display:block;color:var(--foreground2);margin-bottom:0.25rem;") do
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
