# frozen_string_literal: true

class Views::Admin::USPS::PaymentAccounts::Edit < Views::Base
  def initialize(payment_account:)
    @payment_account = payment_account
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "Edit Payment Account")
    render Components::Admin::USPS::PaymentAccounts::Form.new(payment_account: @payment_account)
  end
end
