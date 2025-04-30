module Public
  class MailController < ApplicationController
    before_action :authenticate_public_user!

    def index
      @mail =
        Warehouse::Order.where(recipient_email: current_public_user.email).includes(:line_items) +
          Letter.where(recipient_email: current_public_user.email).includes(:iv_mtr_events)
    end
  end
end