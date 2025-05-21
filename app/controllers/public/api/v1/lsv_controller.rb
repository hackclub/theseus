module Public
  module API
    module V1
      class LSVController < ApplicationController
        def index
          @lsv = LSV::TYPES.map { |type| type.find_by_email(current_public_user.email) }.flatten
          render :index
        end

        def show
          @lsv = LSV::SLUGS[params[:slug].to_sym]&.find(params[:id])
          raise ActiveRecord::RecordNotFound unless @lsv && @lsv.email == current_public_user&.email
        rescue Norairrecord::RecordNotFoundError
          raise ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
