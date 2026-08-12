# frozen_string_literal: true

class Views::Admin::USPS::PaymentAccounts::Show < Views::Base
  def initialize(payment_account:)
    @payment_account = payment_account
  end

  def view_template
    render Components::Shared::PageToolbar.new(
      title: @payment_account.name || "Payment Account",
      action_href: edit_admin_usps_payment_account_path(@payment_account),
      action_label: "✎ Edit"
    )

    section do
      div(class: "detail-grid") do
        span(class: "detail-label") { "Name" }
        span { @payment_account.name }

        span(class: "detail-label") { "Type" }
        span { type_badge }

        span(class: "detail-label") { "Mailer ID" }
        span { mailer_id_label }

        if @payment_account.EPS?
          span(class: "detail-label") { "Account Number" }
          span { @payment_account.account_number }
        end

        if @payment_account.PERMIT?
          span(class: "detail-label") { "Permit Number" }
          span { @payment_account.permit_number }

          span(class: "detail-label") { "Permit ZIP" }
          span { @payment_account.permit_zip }
        end

        span(class: "detail-label") { "Manifest MID" }
        span do
          if @payment_account.manifest_mid.present?
            plain @payment_account.manifest_mid
          else
            span(class: "text-muted") { "—" }
          end
        end

        span(class: "detail-label") { "ACH" }
        span { ach_badge }

        span(class: "detail-label") { "Created" }
        span(class: "text-muted") { @payment_account.created_at.strftime("%b %d, %Y %H:%M") }

        span(class: "detail-label") { "Updated" }
        span(class: "text-muted") { @payment_account.updated_at.strftime("%b %d, %Y %H:%M") }
      end
    end
  end

  private

  def type_badge
    case @payment_account.account_type
    when "EPS"
      span(class: "badge badge-info") { "EPS" }
    when "PERMIT"
      span(class: "badge badge-success") { "PERMIT" }
    else
      span(class: "badge") { @payment_account.account_type.to_s }
    end
  end

  def ach_badge
    if @payment_account.ach?
      span(class: "badge badge-success") { "ACH" }
    else
      span(class: "badge") { "No" }
    end
  end

  def mailer_id_label
    mid = @payment_account.usps_mailer_id
    mid.name.present? ? "#{mid.name} (#{mid.mid})" : mid.mid
  end
end
