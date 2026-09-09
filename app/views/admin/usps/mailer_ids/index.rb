class Views::Admin::USPS::MailerIds::Index < Views::Base
  def initialize(mailer_ids:)
    @mailer_ids = mailer_ids
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Mailer IDs",
      jumpcode_path: admin_usps_mailer_ids_path,
      action_href: new_admin_usps_mailer_id_path,
      action_label: "+ New Mailer ID"
    )

    table do
      thead do
        tr do
          th { "Name" }
          th { "CRID" }
          th { "MID" }
          th(class: "text-right") { "" }
        end
      end
      tbody do
        @mailer_ids.each do |mailer_id|
          tr do
            td do
              a(href: admin_usps_mailer_id_path(mailer_id), class: "link-strong") { mailer_id.name }
            end
            td(class: "text-muted") { mailer_id.crid }
            td(class: "text-muted") { mailer_id.mid }
            td(class: "actions-cell") do
              a(href: edit_admin_usps_mailer_id_path(mailer_id), class: "icon-link") { "✎" }
              button_to "✕", admin_usps_mailer_id_path(mailer_id), method: :delete, form: { class: "form-inline" }, class: "btn-link-danger", onclick: "return confirm('Delete this mailer ID?')"
            end
          end
        end
      end
    end
  end
end
