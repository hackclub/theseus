module Public
  module API
    module V1
      class ApplicationController < ActionController::API
        prepend_view_path "app/views/public/api/v1"

        attr_reader :current_public_user

        before_action :authenticate!
        before_action :set_expand

        include ActionController::HttpAuthentication::Token::ControllerMethods
        include PaperTrail::Rails::Controller

        # Declared first so everything below wins: Rescuable matches the most
        # recently declared handler.
        rescue_from StandardError do |e|
          Sentry.capture_exception(e)
          Rails.logger.error("[public api] unhandled #{e.class}: #{e.message}")
          render json: { error: "internal_error" }, status: :internal_server_error
        end

        rescue_from Pundit::NotAuthorizedError do |e|
          render json: { error: "not_authorized" }, status: :forbidden
        end

        rescue_from ActiveRecord::RecordNotFound do |e|
          render json: { error: "resource_not_found", message: ("Couldn't locate that #{e.model.constantize.model_name.human}." if e.model) }.compact_blank, status: :not_found
        end

        private

        def user_for_paper_trail
          current_public_user&.id
        end

        def info_for_paper_trail
          { ip: request.remote_ip, api_key_id: @current_token&.id }
        end

        def set_expand
          @expand = params[:expand].to_s.split(",").map { |e| e.strip.to_sym }
        end

        def authenticate!
          @current_token = authenticate_with_http_token { |t, _options| Public::APIKey.find_by(token: t) }
          unless @current_token&.active?
            return render json: { error: "invalid_auth" }, status: :unauthorized
          end

          @current_public_user = @current_token.public_user
        end
      end
    end
  end
end
