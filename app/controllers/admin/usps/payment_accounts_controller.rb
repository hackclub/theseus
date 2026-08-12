# frozen_string_literal: true

module Admin
  module USPS
    class PaymentAccountsController < Admin::ApplicationController
      skip_after_action :verify_authorized

      def index
        @payment_accounts = ::USPS::PaymentAccount.includes(:usps_mailer_id).order(:name)
        render Views::Admin::USPS::PaymentAccounts::Index.new(payment_accounts: @payment_accounts)
      end

      def show
        render Views::Admin::USPS::PaymentAccounts::Show.new(payment_account: resource)
      end

      def new
        render Views::Admin::USPS::PaymentAccounts::New.new(payment_account: ::USPS::PaymentAccount.new)
      end

      def create
        @payment_account = ::USPS::PaymentAccount.new(payment_account_params)
        if @payment_account.save
          redirect_to admin_usps_payment_accounts_path, notice: "Payment account created."
        else
          render Views::Admin::USPS::PaymentAccounts::New.new(payment_account: @payment_account), status: :unprocessable_entity
        end
      end

      def edit
        render Views::Admin::USPS::PaymentAccounts::Edit.new(payment_account: resource)
      end

      def update
        if resource.update(payment_account_params)
          redirect_to admin_usps_payment_account_path(resource), notice: "Payment account updated."
        else
          render Views::Admin::USPS::PaymentAccounts::Edit.new(payment_account: resource), status: :unprocessable_entity
        end
      end

      def destroy
        resource.destroy
        redirect_to admin_usps_payment_accounts_path, notice: "Payment account deleted."
      end

      private

      def resource = @resource ||= ::USPS::PaymentAccount.find(params[:id])

      def payment_account_params
        params.require(:usps_payment_account).permit(
          :name, :account_type, :account_number, :permit_number,
          :permit_zip, :manifest_mid, :ach, :usps_mailer_id_id
        )
      end
    end
  end
end
