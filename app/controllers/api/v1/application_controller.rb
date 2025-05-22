module API
  module V1
    class ApplicationController < ActionController::API
      prepend_view_path Rails.root.join("app/views/api/v1")
      attr_reader :current_user

      before_action :authenticate!
      before_action :set_expand
      before_action :set_pii

      include Pundit::Authorization
      include ActionController::HttpAuthentication::Token::ControllerMethods

      rescue_from Pundit::NotAuthorizedError do |e|
        render json: { error: "not_authorized" }, status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "resource_not_found", message: ("Couldn't locate that #{e.model.constantize.model_name.human}." if e.model) }.compact_blank, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "validation_error", messages: e.record.errors.full_messages }, status: :bad_request
      end

      rescue_from ActiveRecord::RecordNotUnique do |e|
        render json: { error: "idempotency_error", messages: ["a record by that idempotency key already exists!"] }, status: :bad_request
      end

      private

      def set_expand
        @expand = params[:expand].to_s.split(",").map { |e| e.strip.to_sym }
      end

      def set_pii
        @pii = current_token&.pii?
      end

      def authenticate!
        @current_token = authenticate_with_http_token { |t, _options| APIKey.find_by(token: t) }
        unless @current_token&.active?
          return render json: { error: "invalid_auth" }, status: :unauthorized
        end
        @current_user = if current_token&.may_impersonate? && params[:impersonate].present?
            begin
              User.find_by!(slack_id: params[:impersonate])
            rescue ActiveRecord::RecordNotFound
              render json: { error: "impersonate_error", message: "couldn't find that user" }, status: :bad_request
            end
          else
            current_token&.user
          end
      end

      attr_reader :current_token
    end
  end
end
