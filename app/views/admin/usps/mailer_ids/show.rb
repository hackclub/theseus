class Views::Admin::USPS::MailerIds::Show < Views::Base
  def initialize(mailer_id:)
    @mailer_id = mailer_id
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: @mailer_id.name,
      action_href: edit_admin_usps_mailer_id_path(@mailer_id),
      action_label: "✎ Edit"
    )

    section do
      div(class: "detail-grid") do
        span(class: "detail-label") { "Name" }
        span { @mailer_id.name }

        span(class: "detail-label") { "CRID" }
        span { @mailer_id.crid }

        span(class: "detail-label") { "MID" }
        span { @mailer_id.mid }

        span(class: "detail-label") { "Sequence Number" }
        span(class: "text-muted") { @mailer_id.sequence_number.to_s }

        span(class: "detail-label") { "Rollover Count" }
        span(class: "text-muted") { @mailer_id.rollover_count.to_s }

        span(class: "detail-label") { "Created" }
        span(class: "text-muted") { @mailer_id.created_at.strftime("%b %d, %Y %H:%M") }

        span(class: "detail-label") { "Updated" }
        span(class: "text-muted") { @mailer_id.updated_at.strftime("%b %d, %Y %H:%M") }
      end
    end
  end
end
