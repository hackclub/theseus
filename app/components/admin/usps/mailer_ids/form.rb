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
        render Components::Shared::FormField.new(label: "Name", name: "usps_mailer_id[name]", value: @mailer_id.name, required: true, hint: "Human-readable label")
        render Components::Shared::FormField.new(label: "CRID", name: "usps_mailer_id[crid]", value: @mailer_id.crid, required: true, hint: "USPS Customer Registration ID")
        render Components::Shared::FormField.new(label: "MID", name: "usps_mailer_id[mid]", value: @mailer_id.mid, required: true, hint: "USPS Mailer Identifier")

        div(class: "form-actions") do
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
end
