module Admin
  module USPS
    class MailerIdsController < Admin::ApplicationController
      skip_after_action :verify_authorized

      def index
        @mailer_ids = ::USPS::MailerId.all.order(:name)
        render Views::Admin::USPS::MailerIds::Index.new(mailer_ids: @mailer_ids)
      end

      def show
        render Views::Admin::USPS::MailerIds::Show.new(mailer_id: resource)
      end

      def new
        render Views::Admin::USPS::MailerIds::New.new(mailer_id: ::USPS::MailerId.new)
      end

      def create
        @mailer_id = ::USPS::MailerId.new(mailer_id_params)
        if @mailer_id.save
          redirect_to admin_usps_mailer_ids_path, notice: "Created."
        else
          render Views::Admin::USPS::MailerIds::New.new(mailer_id: @mailer_id), status: :unprocessable_entity
        end
      end

      def edit
        render Views::Admin::USPS::MailerIds::Edit.new(mailer_id: resource)
      end

      def update
        if resource.update(mailer_id_params)
          redirect_to admin_usps_mailer_id_path(resource), notice: "Updated."
        else
          render Views::Admin::USPS::MailerIds::Edit.new(mailer_id: resource), status: :unprocessable_entity
        end
      end

      def destroy
        resource.destroy
        redirect_to admin_usps_mailer_ids_path, notice: "Deleted."
      end

      private

      def resource = @resource ||= ::USPS::MailerId.find(params[:id])
      def mailer_id_params = params.require(:usps_mailer_id).permit(:name, :crid, :mid)
    end
  end
end
