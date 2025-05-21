module Public
  module API
    module V1
      class MailController < ApplicationController
        def index
          @mail =
            Warehouse::Order.where(recipient_email: current_public_user.email) +
            Letter.where(recipient_email: current_public_user.email)
          unless params[:no_load_lsv]
            @mail += LSV::TYPES.map { |type| type.find_by_email(current_public_user.email) }.flatten
          end
          @mail.sort_by!(&:created_at).reverse!
          render :index
        end
      end
    end
  end
end
