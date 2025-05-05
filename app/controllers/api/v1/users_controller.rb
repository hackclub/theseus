module API
  module V1
    class UsersController < ApplicationController
      def show
        @user = authorize current_user
      end

    end
  end
end