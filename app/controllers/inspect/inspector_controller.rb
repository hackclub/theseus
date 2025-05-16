module Inspect
  class InspectorController < ApplicationController
    skip_after_action :verify_authorized
    before_action :set_record
    before_action do
      unless current_user.admin?
        redirect_to root_path, alert: "you are not authorized to access this page."
      end
    end

    def show
      @linked_fields = self.class::LINKED_FIELDS.each_with_object({}) do |field, hash|
        hash[field] = nil
        res = @record.send(field)
        next if res.blank?
        hash[field] = url_for(res) if res.present?
      rescue ActionController::RoutingError
      end
      render "inspect/show"
    end

    private

    def set_record
      @record = self.class::MODEL.find_by_public_id(params[:id]) || self.class::MODEL.find(params[:id])
    end
  end
end
