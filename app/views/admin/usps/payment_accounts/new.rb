# frozen_string_literal: true

class Views::Admin::USPS::PaymentAccounts::New < Views::Base
  def initialize(payment_account:)
    @payment_account = payment_account
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "New Payment Account")
    render Components::Admin::USPS::PaymentAccounts::Form.new(payment_account: @payment_account)
  end
end
