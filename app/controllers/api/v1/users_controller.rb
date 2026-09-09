module API
  module V1
    class UsersController < ApplicationController
      def show
        @user = authorize current_user
      end

      def create
        authorize User

        if identifier_params.values.none?(&:present?)
          return render json: { error: "missing_parameter", messages: ["provide at least one of hca_id, slack_id, or email"] }, status: :bad_request
        end

        @user = find_existing_user
        newly_created = @user.nil?
        @user ||= User.new
        @user.assign_attributes(user_params)
        @user.save!

        render :show, status: newly_created ? :created : :ok
      end

      private

      def find_existing_user
        ids = identifier_params
        user = nil
        user ||= User.find_by(hca_id: ids[:hca_id]) if ids[:hca_id].present?
        user ||= User.find_by(slack_id: ids[:slack_id]) if ids[:slack_id].present?
        user ||= User.find_by(email: ids[:email]) if ids[:email].present?
        user
      end

      def identifier_params
        user_params.slice(:hca_id, :slack_id, :email)
      end

      def user_params
        params.require(:user).permit(
          :email, :username, :slack_id, :hca_id,
          :is_admin, :can_warehouse, :can_impersonate_public, :can_use_indicia,
        )
      end
    end
  end
end