class Views::Admin::USPS::MailerIds::Index < Views::Base
  def initialize(mailer_ids:)
    @mailer_ids = mailer_ids
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: "Mailer IDs",
      action_href: new_admin_usps_mailer_id_path,
      action_label: "+ New Mailer ID"
    )

    table do
      thead do
        tr do
          th { "Name" }
          th { "CRID" }
          th { "MID" }
          th(style: "text-align: right;") { "" }
        end
      end
      tbody do
        @mailer_ids.each do |mailer_id|
          tr do
            td do
              a(href: admin_usps_mailer_id_path(mailer_id), style: "text-decoration:none;font-weight:600;") { mailer_id.name }
            end
            td(class: "text-muted") { mailer_id.crid }
            td(class: "text-muted") { mailer_id.mid }
            td(style: "text-align:right;") do
              a(href: edit_admin_usps_mailer_id_path(mailer_id), style: "color:GrayText;margin-right:0.5rem;") { "✎" }
              a(href: admin_usps_mailer_id_path(mailer_id), data: { turbo_method: :delete, turbo_confirm: "Delete this mailer ID?" }, style: "color:var(--red);") { "✕" }
            end
          end
        end
      end
    end
  end
end
