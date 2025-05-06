module Administrate
  module ArrayParameterHandler
    extend ActiveSupport::Concern

    included do
      before_action :handle_array_parameters
    end

    private

    def handle_array_parameters
      return unless params[:warehouse_order].present?

      params[:warehouse_order].each do |key, value|
        if value.is_a?(String) && value.include?(",")
          params[:warehouse_order][key] = value.split(",").map(&:strip)
        end
      end
    end
  end
end 