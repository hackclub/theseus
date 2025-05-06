module Public
  class MailController < ApplicationController
    before_action :authenticate_public_user!

    def index
      @mail =
        Warehouse::Order.where(recipient_email: current_public_user.email) +
          Letter.where(recipient_email: current_public_user.email)
      unless params[:no_load_lsv]
        @mail += LSV::TYPES.map { |type| type.find_by_email(current_public_user.email) }.flatten
      end
      @mail.sort_by!(&:created_at).reverse!
    end
  end
end
