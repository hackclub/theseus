module Public
  module API
    module V1
      class UsersController < ApplicationController
        def me
          @user = current_public_user
          render :show
        end
      end
    end
  end
end
