module Public
  module API
    module V1
      class LettersController < ApplicationController
        def index
          @letters = Letter.where(recipient_email: current_public_user.email)
        end

        def show
          @letter = Letter.where(recipient_email: current_public_user.email).find_by_public_id!(params[:id])
        end
      end
    end
  end
end
