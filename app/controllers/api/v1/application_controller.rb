module API
  module V1
    class ApplicationController < ActionController::API

      before_action :set_expand

      rescue_from Pundit::NotAuthorizedError do |e|
        render json: { error: "not_authorized" }, status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "resource_not_found", message: ("Couldn't locate that #{e.model.constantize.model_name.human}." if e.model) }.compact_blank, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "invalid_operation", messages: e.record.errors.full_messages }, status: :bad_request
      end

      def set_expand
        @expand = params[:expand].to_s.split(",").map { |e| e.strip.to_sym }
      end
    end
  end
end
